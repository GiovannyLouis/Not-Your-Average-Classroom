//
//  AppViewModel.swift
//  NYAC
//
//  Created by Vrz on 07/11/26.
//

import Foundation
import Observation

/// The app above the game: which screen is showing, and the player's settings.
/// It makes a fresh GameViewModel for every run and takes the player back to the lobby when a run is left.
@MainActor
@Observable
final class AppViewModel {

    private(set) var screen: AppScreen = .lobby

    /// Lives as long as the app does, so the lobby and every run share the same values.
    let settings = GameSettings()

    // MARK: Navigation

    func startGame() {
        guard case .lobby = screen else { return }

        let game = GameViewModel(settings: settings)
        game.onBackToLobby = { [weak self] in self?.backToLobby() }
        screen = .game(game)
    }

    func openSettings() {
        guard case .lobby = screen else { return }
        screen = .settings
    }

    func backToLobby() {
        screen = .lobby
    }
}
