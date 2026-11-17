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
/// It also keeps what the player has set (and done) between launches: it restores the settings when the app opens
/// and saves them again every time one changes.
@MainActor
@Observable
final class AppViewModel {

    private(set) var screen: AppScreen = .lobby

    // These live as long as the app does, so the lobby, the settings and every run share the same ones.

    let settings: GameSettings

    /// What the game remembers between launches: the settings, how many games were played, the best completion time.
    /// Every run gets it too. `store.gamesPlayed == 0` is the check for a player who has never played (a tutorial, say).
    let store: PlayerStore

    /// The one camera of the app. It opens when the app does (see `start`), so any screen can use the head tracking.
    let peek: PeekViewModel

    /// The classroom behind the lobby and its settings. It is made once, so the parallax carries on when the player
    /// goes from one to the other, and when they come back from a run.
    let menuScene: MenuScene

    convenience init() {
        self.init(store: PlayerStore())
    }

    init(store: PlayerStore) {
        let settings = GameSettings()
        store.load(into: settings)          // the saved values replace the defaults before anything reads them
        let peek = PeekViewModel(settings: settings)
        self.settings = settings
        self.store = store
        self.peek = peek
        self.menuScene = MenuScene(peek: peek)

        observeSettings()
    }

    // MARK: Saving

    /// Saves the settings every time the player changes one, from either settings screen.
    private func observeSettings() {
        withObservationTracking {
            _ = settings.thresholdY
            _ = settings.sensitivity
        } onChange: { [weak self] in
            // onChange runs just before the new value lands, so the save waits one hop to read the new value.
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.store.save(self.settings)
                self.observeSettings()
            }
        }
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

        let game = GameViewModel(settings: settings, peek: peek, store: store)
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
