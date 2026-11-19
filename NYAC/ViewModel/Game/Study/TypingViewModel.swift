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

    /// Set when generation failed and the fallback text is being used.
    private(set) var notice: String?

    /// How many wrong characters have been typed so far (it only goes up, deleting them does not take it back).
    /// It goes up in the same moment the wrong character shows up in red, and the view shakes every time it changes.
    private(set) var wrongKeyCount = 0

    private var test = TypingTest(text: "")

    /// Called once when the whole text has been typed correctly. The game uses it to mark this objective as done.
    @ObservationIgnored var onCompleted: (() -> Void)?

    @ObservationIgnored private let textService: any TextGenerating
    @ObservationIgnored private let sound: SoundService
    @ObservationIgnored private var startDate: Date?

    init(textService: any TextGenerating = FoundationModelTextService(), sound: SoundService = .shared) {
        self.textService = textService
        self.sound = sound
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

        // Every character of the text has a key already (right or wrong): there is nothing left to type onto.
        let index = test.typed.count
        guard index < test.text.count else { return }

        // The key is wrong when it is not the character the text asks for here. That is exactly when it shows up in red.
        let isWrong = character != test.text[index]

        test.type(character)
        sound.play(.typing)
        if isWrong { wrongKeyCount += 1 }

        if test.isCompleted { finish() }
    }

    func deleteLast() {
        guard status == .running, !test.typed.isEmpty else { return }
        test.deleteLast()
        sound.play(.backspace)
    }

    /// Throws the current attempt away and starts over with a freshly generated text.
    func reset() {
        guard status != .loading else { return }
        Task { await loadNewText() }
    }

    // MARK: Progress
    // The clock lives in the game. This view model only remembers when typing began
    // and tells the game once the text is finished.

    private func start() {
        status = .running
        startDate = Date()
    }

    private func finish() {
        status = .finished
        onCompleted?()
    }
}
