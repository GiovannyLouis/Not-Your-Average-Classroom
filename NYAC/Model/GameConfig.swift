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
}
