//
//  FoundationModelTextService.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//

import Foundation
import FoundationModels

/// Generates the typing text with Apple's on-device model.
struct FoundationModelTextService: TextGenerating {

    /// ✏️ Tweak these two to change the kind of text you get.
    private static let instructions = """
    You write practice passages for a typing test. Reply with the passage only: \
    plain text, no title, no markdown, no lists, no emojis, no quotation marks, \
    and no introduction or closing remarks. Use only letters, numbers and basic \
    punctuation found on a standard US keyboard.
    """

    private static let prompt = """
    Write exactly two paragraphs of fun facts about biology. \
    Each paragraph should be about 40 words long. \
    Separate the two paragraphs with a blank line.
    """

    func generateText() async throws -> String {
        try checkAvailability()

        // A fresh session per request: a session remembers earlier turns, which we don't want here.
        let session = LanguageModelSession(instructions: Self.instructions)

        var options = GenerationOptions()
        options.temperature = 0.9   // 0...1, higher = more variety between runs

        let response = try await session.respond(to: Self.prompt, options: options)
        let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { throw TextGenerationError.emptyResponse }
        return text
    }

    private func checkAvailability() throws {
        switch SystemLanguageModel.default.availability {
        case .available:
            return
        case .unavailable(.appleIntelligenceNotEnabled):
            throw TextGenerationError.unavailable(
                "Apple Intelligence is turned off. Enable it in System Settings.")
        case .unavailable(.modelNotReady):
            throw TextGenerationError.unavailable(
                "The on-device model is still downloading. Try again in a bit.")
        case .unavailable(.deviceNotEligible):
            throw TextGenerationError.unavailable(
                "This Mac doesn't support Apple Intelligence.")
        case .unavailable:
            throw TextGenerationError.unavailable(
                "The on-device model is unavailable.")
        }
    }
}
