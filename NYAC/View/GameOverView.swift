//
//  GameOverView.swift
//  NYAC
//
//  Created by Vrz on 06/11/26.
//

import SwiftUI

/// The game over screen: one template for every ending. It dims whatever is behind it (the game that just ended)
/// and puts a card in front: a title, a message, the time if there is one, and a button.
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

            if let stat = content.stat {
                statBox(stat)
                    .padding(.top, 14)
            }

            backButton
                .padding(.top, 4)
        }
        .foregroundStyle(.black)
        .padding(.vertical, 28)
        .padding(.horizontal, 32)
        .frame(width: 720)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.black, lineWidth: 5))
    }

    private func statBox(_ stat: GameOverContent.Stat) -> some View {
        VStack(spacing: 2) {
            Text(stat.label)
                .font(.system(size: 18))
            Text(stat.value)
                .font(.system(size: 26))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.black, lineWidth: 5))
        .padding(.horizontal, 24)       // a bit narrower than the card, like the sketch
    }

    private var backButton: some View {
        Button(action: onBackToLobby) {
            Text("Restart")
                .font(.system(size: 18))
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .overlay(Capsule().stroke(.black, lineWidth: 5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Win") {
    GameOverView(content: GameOverContent(result: .won(completionTime: 83)), onBackToLobby: {})
        .frame(width: 1000, height: 650)
}

#Preview("Time's up") {
    GameOverView(content: GameOverContent(result: .timeUp), onBackToLobby: {})
        .frame(width: 1000, height: 650)
}

#Preview("Caught") {
    GameOverView(content: GameOverContent(result: .caught(survivedFor: 83)), onBackToLobby: {})
        .frame(width: 1000, height: 650)
}
