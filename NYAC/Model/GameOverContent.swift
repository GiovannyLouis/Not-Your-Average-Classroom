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

    init(result: GameResult) {
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
    }

    /// Minutes and seconds, like a stopwatch: 83 seconds is "01:23".
    private static func clockText(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
