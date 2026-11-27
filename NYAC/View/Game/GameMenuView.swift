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
                SettingsView(settings: game.settings, peek: game.peek, onBack: { game.closeSettings() })
            }
        }
        .ignoresSafeArea()
    }

    private var mainCard: some View {
        VStack(spacing: 18) {
            Text("Menu")
                .font(UIFont.title(size: 44))

            CutoutButton(title: "Settings") { game.openSettings() }
            CutoutButton(title: "Back to Lobby") { game.backToLobby() }

            Text("Press Esc to close")
                .font(UIFont.body(size: 14))
                .foregroundStyle(PaperPalette.inkSoft)
                .padding(.top, 4)
        }
        .cardStyle(width: 420)
    }
}
