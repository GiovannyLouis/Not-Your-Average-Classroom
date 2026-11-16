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
        case .lobby, .settings:
            // One view for both, so the room behind the board stays (and keeps moving) when the page changes.
            MenuView(app: app)

        case .game(let game):
            GameView(game: game)
        }
    }
}
