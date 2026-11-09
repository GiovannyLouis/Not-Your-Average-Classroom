//
//  RootView.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//


import SwiftUI

/// The top of the app: shows whichever screen the app is on.
struct RootView: View {
    let app: AppViewModel

    var body: some View {
        switch app.screen {
        case .lobby:
            LobbyView(app: app)

        case .settings:
            SettingsView(settings: app.settings, peek: app.peek, onBack: { app.backToLobby() })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)

        case .game(let game):
            GameView(game: game)
        }
    }
}
