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
                .font(.system(size: 64))

            Text(content.message)
                .font(.system(size: 18))
                .multilineTextAlignment(.center)

            // This run's time and the record, side by side. Either one can be missing (a time up has no time of its own,
            // and the record does not exist until the first win), and the one that is left takes the whole width.
            if content.stat != nil || content.bestStat != nil {
                HStack(spacing: 16) {
                    if let stat = content.stat {
                        statBox(stat)
                    }
                    if let bestStat = content.bestStat {
                        statBox(bestStat)
                    }
                }
                .padding(.horizontal, 24)       // a bit narrower than the card, like the sketch
                .padding(.top, 14)
            }

            PillButton(title: "Back to Lobby", action: onBackToLobby)
                .padding(.top, 4)
        }
        .cardStyle()
    }

    private func statBox(_ stat: GameOverContent.Stat) -> some View {
        VStack(spacing: 2) {
            Text(stat.label)
                .font(.system(size: 18))
                .lineLimit(1)
                .minimumScaleFactor(0.7)        // "New best completion time!" is the longest label
            Text(stat.value)
                .font(.system(size: 26))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.black, lineWidth: 5))
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
