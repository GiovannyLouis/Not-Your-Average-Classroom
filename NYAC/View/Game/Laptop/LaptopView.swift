//
//  LaptopView.swift
//  NYAC
//
//  Created by Vrz on 30/10/26.
//

import SwiftUI
 
/// The laptop: one screen that holds Study and Minigame (the clock and the progress live in the game's HUD, not here).
/// Both tabs are always in the view tree (the hidden one is just transparent), so neither is
/// paused or rebuilt when you switch. This view is also the only place that reads the keyboard:
/// it hands every key to the tab that is on screen and to nobody else.
struct LaptopView: View {
    /// Owned by whoever shows the laptop. LaptopView itself stays cheap to create, because the
    /// parallax layer rebuilds it every frame to move it.
    let game: GameViewModel
    @FocusState private var isFocused: Bool

    private var laptop: LaptopViewModel { game.laptop }
 
    init(game: GameViewModel) {
        self.game = game
    }
 
    var body: some View {
        screen
            .frame(width: LaptopLayout.size.width, height: LaptopLayout.size.height)
            .focusable()
            .focused($isFocused)
            .focusEffectDisabled()
            .onAppear { isFocused = true }
            // Nothing else in the game needs the keyboard, so if focus ever lands elsewhere
            // (clicking a slider in the menu, say) take it straight back.
            .onChange(of: isFocused) { _, focused in
                if !focused { isFocused = true }
            }
            .onKeyPress { press in handle(press) }
    }
 
    // MARK: - Screen
 
    private var screen: some View {
        ZStack {
            TypingView(viewModel: laptop.study)
                .opacity(laptop.activeTab == .study ? 1 : 0)

            MinigameView(viewModel: laptop.minigame, scene: laptop.minigameScene)
                .opacity(laptop.activeTab == .minigame ? 1 : 0)
        }
        .frame(width: LaptopLayout.screenSize.width, height: LaptopLayout.screenSize.height)
        .clipped()
    }

    // MARK: - Keyboard
 
    private func handle(_ press: KeyPress) -> KeyPress.Result {
        // Escape always belongs to the game: it opens and closes the menu. It never reaches either tab.
        if press.key == .escape {
            if press.phase == .down { game.toggleMenu() }
            return .handled
        }

        // Tab always belongs to the laptop. It never reaches either tab.
        if press.key == .tab {
            if press.phase == .down { laptop.switchTab() }
            return .handled
        }

        switch laptop.activeTab {
        case .study:    return handleStudy(press)
        case .minigame: return handleMinigame(press)
        }
    }
 
    /// WASD or arrow keys, one hop per key press (holding the key does not repeat).
    private func handleMinigame(_ press: KeyPress) -> KeyPress.Result {
        let direction: Move
        switch press.key {
        case .upArrow:    direction = .up
        case .downArrow:  direction = .down
        case .leftArrow:  direction = .left
        case .rightArrow: direction = .right
        default:
            switch press.characters.lowercased() {
            case "w": direction = .up
            case "s": direction = .down
            case "a": direction = .left
            case "d": direction = .right
            default:  return .ignored
            }
        }
 
        if press.phase == .down { laptop.move(direction) }
        return .handled
    }
 
    private func handleStudy(_ press: KeyPress) -> KeyPress.Result {
        if isBackspace(press) {
            laptop.deleteLast()
            return .handled
        }
 
        guard press.modifiers.isDisjoint(with: [.command, .control]),
              press.characters.count == 1,
              let character = press.characters.first,
              character == " " || character.isLetter || character.isNumber
                || character.isPunctuation || character.isSymbol
        else { return .ignored }
 
        laptop.type(character)
        return .handled
    }
 
    /// The Mac Backspace key sends U+007F, which SwiftUI reports as `.deleteForward`
    /// rather than `.delete`, so accept both (plus the raw characters) to be safe.
    private func isBackspace(_ press: KeyPress) -> Bool {
        press.key == .delete
            || press.key == .deleteForward
            || press.characters == "\u{7F}"
            || press.characters == "\u{8}"
    }
}
 
#Preview {
    let settings = GameSettings()
    LaptopView(game: GameViewModel(settings: settings, peek: PeekViewModel(settings: settings)))
}
