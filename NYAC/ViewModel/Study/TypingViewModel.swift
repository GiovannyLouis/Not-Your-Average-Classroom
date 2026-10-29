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

    /// Test length in seconds.
    static let duration = 300

    private(set) var status: TypingStatus = .loading
    private(set) var timeRemaining = TypingViewModel.duration
    private(set) var wpm = 0

    /// Set when generation failed and the fallback text is being used.
    private(set) var notice: String?

    private var test = TypingTest(text: "")

    @ObservationIgnored private let textService: any TextGenerating
    @ObservationIgnored private var timerTask: Task<Void, Never>?
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
        timerTask?.cancel()
        timerTask = nil
        startDate = nil
        timeRemaining = Self.duration
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

    // MARK: Timer

    private func start() {
        status = .running
        startDate = Date()

        timerTask = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        timeRemaining -= 1
        if timeRemaining <= 0 { finish() }
    }

    private func finish() {
        timerTask?.cancel()
        timerTask = nil
        status = .finished

        // Standard WPM: one "word" = 5 correct characters.
        let elapsed = min(Date().timeIntervalSince(startDate ?? Date()), Double(Self.duration))
        let minutes = max(elapsed, 1) / 60
        wpm = Int((Double(test.correctCount) / 5) / minutes)
    }
}
