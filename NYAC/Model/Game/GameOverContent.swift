//
//  GameOverContent.swift
//  NYAC
//
//  Created by Vrz on 06/11/26.
//

import Foundation

/// What the game over screen says. The screen is one template for every ending,
/// and this turns a GameResult into the words and the time that go into it.
struct GameOverContent {

    /// The boxed line under the message: a label and a time such as "01:23".
    struct Stat {
        let label: String
        let value: String
    }

    let title: String
    let message: String

    /// Nil when the ending has no time to show.
    let stat: Stat?

    /// The player's best completion time, next to the time above, win or lose. It says "New best completion time!"
    /// when this run just set the record. Nil while the player has never won, since there is no record to show yet.
    let bestStat: Stat?

    /// `bestCompletionTime` is the record as it stands after this run, and `isNewBest` says this run just set it.
    init(result: GameResult, bestCompletionTime: TimeInterval? = nil, isNewBest: Bool = false) {
        switch result {
        case .won(let completionTime):
            title = "YOU WIN"
            message = "You finished both the game and study before the class ended!"
            stat = Stat(label: "Completion Time", value: Self.clockText(completionTime))

        case .timeUp:
            title = "YOU LOSE"
            message = "You failed to finish both game and study within the class session!"
            stat = nil

        case .caught(let survivedFor):
            title = "YOU LOSE"
            message = "You got caught playing game in the middle of the class!"
            stat = Stat(label: "Time", value: Self.clockText(survivedFor))
        }

        if let bestCompletionTime {
            bestStat = Stat(label: isNewBest ? "New best completion time!" : "Best completion time",
                            value: Self.clockText(bestCompletionTime))
        } else {
            bestStat = nil
        }
    }

    /// Minutes and seconds, like a stopwatch: 83 seconds is "01:23".
    private static func clockText(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
