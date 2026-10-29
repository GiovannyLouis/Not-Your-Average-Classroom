//
//  TextGenerating.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//


// MARK: - Service contract

/// Anything that can produce the text the player has to type.
/// The ViewModel only knows about this protocol, so the source of the text
/// (Foundation Models, a server, a hard-coded list, a test mock) can be swapped freely.
protocol TextGenerating {
    func generateText() async throws -> String
}
