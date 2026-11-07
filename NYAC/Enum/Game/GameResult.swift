//
//  GameResult.swift
//  NYAC
//
//  Created by Vrz on 05/11/26.
//

import Foundation

/// How a run ended, with the one number each ending is judged by. The result screen will read this.
enum GameResult: Equatable {
    /// Every objective was done in time. `completionTime` is how long it took, in seconds.
    case won(completionTime: TimeInterval)

    /// The lecturer saw the player gaming. `survivedFor` is how long the player stayed sneaky, in seconds.
    case caught(survivedFor: TimeInterval)

    /// The clock ran out: the class ended.
    case timeUp
}
