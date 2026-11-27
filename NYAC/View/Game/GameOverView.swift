//
//  GameOverView.swift
//  NYAC
//
//  Created by Vrz on 06/11/26.
//

import SwiftUI

/// The game over screen: one template for every ending. It dims whatever is behind it (the game that just ended)
/// and puts a card in front: a title, a message, the time and the best completion time if there are any, and a button.
/// All the words come from GameOverContent, so this view only lays them out.
struct GameOverView: View {
    let content: GameOverContent

    /// Called when the player taps "Back to Lobby".
    let onBackToLobby: () -> Void

    var body: some View {
        ZStack {
            // Darkens the game behind the card. It also catches clicks, so nothing underneath can be used.
            Color.black.opacity(0.6)

            card
        }
        .ignoresSafeArea()
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 14) {
            Text(content.title)
                .font(UIFont.title(size: 62))

            Text(content.message)
                .font(UIFont.body(size: 18))
                .multilineTextAlignment(.center)

            // This run's time and the record, side by side. Either one can be missing (a time up has no time of its own,
            // and the record does not exist until the first win), and the one that is left takes the whole width.
            if content.stat != nil || content.bestStat != nil {
                HStack(spacing: 18) {
                    if let stat = content.stat {
                        statBox(stat, seed: 11)
                    }
                    if let bestStat = content.bestStat {
                        statBox(bestStat, seed: 29)
                    }
                }
                .padding(.horizontal, 24)       // a bit narrower than the card, like the sketch
                .padding(.top, 14)
            }

            CutoutButton(title: "Back to Lobby", action: onBackToLobby)
                .padding(.top, 8)
        }
        .cardStyle()
    }

    /// A piece of paper with a label and a time. Every box gets its own seed, so the two next to each other are cut differently.
    private func statBox(_ stat: GameOverContent.Stat, seed: Int) -> some View {
        VStack(spacing: 4) {
            Text(stat.label)
                .font(UIFont.body(size: 17))
                .lineLimit(1)
                .minimumScaleFactor(0.7)        // "New best completion time!" is the longest label
            Text(stat.value)
                .font(UIFont.bold(size: 26))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .cutoutBoxStyle(seed: seed)
    }
}

#Preview("Win") {
    GameOverView(content: GameOverContent(result: .won(completionTime: 83), bestCompletionTime: 70), onBackToLobby: {})
        .frame(width: 1000, height: 650)
}

#Preview("Win, new best") {
    GameOverView(content: GameOverContent(result: .won(completionTime: 83), bestCompletionTime: 83, isNewBest: true), onBackToLobby: {})
        .frame(width: 1000, height: 650)
}

#Preview("Win, first time") {
    GameOverView(content: GameOverContent(result: .won(completionTime: 83)), onBackToLobby: {})
        .frame(width: 1000, height: 650)
}

#Preview("Time's up") {
    GameOverView(content: GameOverContent(result: .timeUp, bestCompletionTime: 70), onBackToLobby: {})
        .frame(width: 1000, height: 650)
}

#Preview("Time's up, no record yet") {
    GameOverView(content: GameOverContent(result: .timeUp), onBackToLobby: {})
        .frame(width: 1000, height: 650)
}

#Preview("Caught") {
    GameOverView(content: GameOverContent(result: .caught(survivedFor: 83), bestCompletionTime: 70), onBackToLobby: {})
        .frame(width: 1000, height: 650)
}
