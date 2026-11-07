//
//  LaptopViewModel.swift
//  NYAC
//
//  Created by Vrz on 30/10/26.
//

import Foundation
import Observation

/// The laptop: which tab is on screen, and who gets the keyboard.
///
/// Study and Minigame keep their own state and are never paused or reset when the tab changes.
/// The clock, the win rule and everything else about the run belong to the game.
@MainActor
@Observable
final class LaptopViewModel {

    // MARK: Output for the view

    private(set) var activeTab: LaptopTab = LaptopConfig.startingTab

    // MARK: The two tabs
    // They live as long as the laptop does, so switching tabs never resets them.

    let minigame: MinigameViewModel
    let study: TypingViewModel

    /// The minigame's SpriteKit scene. It lives here instead of in the view, so LaptopView can be
    /// rebuilt as a plain struct (the parallax layer does that every frame) without recreating the scene.
    let minigameScene: MinigameScene

    // MARK: Set by the game

    /// The game turns this on while the run is going and no menu is open. While it is off, the laptop ignores every key.
    @ObservationIgnored var isEnabled = false

    /// Called after the player switches tabs. The game decides what that means
    /// (being on the minigame tab while the lecturer can see the screen gets the player caught).
    @ObservationIgnored var onTabChanged: (() -> Void)?

    init(minigame: MinigameViewModel, study: TypingViewModel) {
        self.minigame = minigame
        self.study = study
        self.minigameScene = MinigameScene(viewModel: minigame)
    }

    // MARK: Tabs

    func switchTab() {
        guard isEnabled else { return }
        activeTab = activeTab.next
        onTabChanged?()
    }

    // MARK: Input from the view
    // Each call only reaches its own tab, and only while that tab is on screen.

    func move(_ direction: Move) {
        guard acceptsInput(for: .minigame) else { return }
        minigame.move(direction)
    }

    func type(_ character: Character) {
        guard acceptsInput(for: .study) else { return }
        study.type(character)
    }

    func deleteLast() {
        guard acceptsInput(for: .study) else { return }
        study.deleteLast()
    }

    private func acceptsInput(for tab: LaptopTab) -> Bool {
        isEnabled && activeTab == tab
    }
}

