//
//  GameConfig.swift
//  NYAC
//
//  Created by Vrz on 05/11/26.
//

import Foundation

/// Fixed rules of the game. What the player can change lives in GameSettings instead.
enum GameConfig {
    /// One clock for the whole game: every objective has to be done inside it.
    static let timeLimit: TimeInterval = 300

    /// How many seconds the player gets to get ready once the study text is written (3, 2, 1, go).
    static let countdownSeconds = 3
}
