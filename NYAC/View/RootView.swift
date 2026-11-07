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

        case .settings(let preview):
            SettingsView(settings: app.settings, preview: preview, onBack: { app.backToLobby() })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .task { await preview.start() }         // the camera only runs while this screen is open
                .onDisappear { preview.stop() }

        case .game(let game):
            GameView(game: game)
        }
    }
}
