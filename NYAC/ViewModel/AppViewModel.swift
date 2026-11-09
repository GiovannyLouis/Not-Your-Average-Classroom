//
//  AppViewModel.swift
//  NYAC
//
//  Created by Vrz on 07/11/26.
//

import Foundation
import Observation

/// The app above the game: which screen is showing, the player's settings and the camera.
/// It makes a fresh GameViewModel for every run and takes the player back to the lobby when a run is left.
@MainActor
@Observable
final class AppViewModel {

    private(set) var screen: AppScreen = .lobby

    // These live as long as the app does, so the lobby, the settings and every run share the same ones.

    let settings: GameSettings

    /// The one camera of the app. It opens when the app does (see `start`), so any screen can use the head tracking.
    let peek: PeekViewModel

    init() {
        let settings = GameSettings()
        self.settings = settings
        self.peek = PeekViewModel(settings: settings)
    }

    // MARK: Lifecycle

    /// Opens the camera. It stays on for as long as the app is open.
    func start() async {
        await peek.start()
    }

    /// Closes the camera. Called when the app's window goes away.
    func stop() {
        peek.stop()
    }

    // MARK: Navigation

    func startGame() {
        guard case .lobby = screen else { return }

        let game = GameViewModel(settings: settings, peek: peek)
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
