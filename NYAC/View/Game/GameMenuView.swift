//
//  GameMenuView.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//

import SwiftUI

/// The menu in front of the game, opened with Escape. The game keeps running behind it, dimmed,
/// so it is not a pause: it shows the two buttons first, and the settings card after "Settings".
struct GameMenuView: View {
    let game: GameViewModel

    var body: some View {
        ZStack {
            // Darkens the game behind the card. It also catches clicks, so nothing underneath can be used.
            Color.black.opacity(0.6)

            switch game.menu {
            case .closed:
                EmptyView()
            case .main:
                mainCard
            case .settings:
                SettingsView(settings: game.settings, onBack: { game.closeSettings() })
            }
        }
        .ignoresSafeArea()
    }

    private var mainCard: some View {
        VStack(spacing: 18) {
            Text("Menu")
                .font(.system(size: 44))

            PillButton(title: "Settings") { game.openSettings() }
            PillButton(title: "Back to Lobby") { game.backToLobby() }

            Text("Press Esc to close")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .padding(.top, 4)
        }
        .cardStyle(width: 420)
    }
}
