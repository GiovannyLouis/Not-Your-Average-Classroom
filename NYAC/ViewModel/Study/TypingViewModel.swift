//
//  TypingViewModel.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class TypingViewModel {
    /// Used when text generation isn't available. ✏️ Replace with your own text if you like.
    static let fallbackText = "The quick brown fox jumps over the lazy dog."

    private(set) var status: TypingStatus = .loading
    private(set) var wpm = 0

    /// Set when generation failed and the fallback text is being used.
    private(set) var notice: String?

    private var test = TypingTest(text: "")

    /// Called once when the whole text has been typed correctly. The laptop uses it to mark this tab as done.
    @ObservationIgnored var onCompleted: (() -> Void)?

    @ObservationIgnored private let textService: any TextGenerating
    @ObservationIgnored private var startDate: Date?

    init(textService: any TextGenerating = FoundationModelTextService()) {
        self.textService = textService
    }

    // MARK: Output for the view

    var words: [TestWord] { test.words }

    /// Index of the character the player has to type next (nil when there is nothing to type).
    var cursorIndex: Int? {
        (status == .idle || status == .running) ? test.typed.count : nil
    }

    /// ID of the word the cursor is in, used to keep it scrolled into view.
    var currentWordID: Int? {
        guard let cursor = cursorIndex else { return nil }
        return words.last(where: { $0.id <= cursor })?.id
    }

    // MARK: Text loading

    /// Generates a new text and gets the game ready for the first keystroke.
    func loadNewText() async {
        startDate = nil
        wpm = 0
        notice = nil
        test = TypingTest(text: "")
        status = .loading

        do {
            let text = try await textService.generateText()
            test = TypingTest(text: text)
        } catch {
            test = TypingTest(text: Self.fallbackText)
            notice = "\(error.localizedDescription) Using sample text."
        }

        status = .idle
    }

    // MARK: Input from the view

    func type(_ character: Character) {
        guard status == .idle || status == .running else { return }
        if status == .idle { start() }

        test.type(character)

        if test.isCompleted { finish() }
    }

    func deleteLast() {
        guard status == .running else { return }
        test.deleteLast()
    }

    /// Throws the current attempt away and starts over with a freshly generated text.
    func reset() {
        guard status != .loading else { return }
        Task { await loadNewText() }
    }

    // MARK: Progress
    // The clock lives in the laptop. This view model only remembers when typing began (for WPM)
    // and tells the laptop once the text is finished.

    private func start() {
        status = .running
        startDate = Date()
    }

    private func finish() {
        status = .finished

        // Standard WPM: one "word" = 5 correct characters.
        let elapsed = Date().timeIntervalSince(startDate ?? Date())
        let minutes = max(elapsed, 1) / 60
        wpm = Int((Double(test.correctCount) / 5) / minutes)

        onCompleted?()
    }
}
