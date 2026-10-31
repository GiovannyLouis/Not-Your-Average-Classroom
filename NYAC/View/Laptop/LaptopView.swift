//
//  LaptopView.swift
//  NYAC
//
//  Created by Vrz on 30/10/26.
//

import SwiftUI
 
/// The laptop: a tab bar with the shared clock on top, and a screen that holds Study and Minigame.
/// Both tabs are always in the view tree (the hidden one is just transparent), so neither is
/// paused or rebuilt when you switch. This view is also the only place that reads the keyboard:
/// it hands every key to the tab that is on screen and to nobody else.
struct LaptopView: View {
    @State private var viewModel: LaptopViewModel
    @State private var minigameScene: MinigameScene
    @FocusState private var isFocused: Bool
 
    init() {
        let laptop = LaptopViewModel()
        _viewModel = State(initialValue: laptop)
        _minigameScene = State(initialValue: MinigameScene(viewModel: laptop.minigame))
    }
 
    var body: some View {
        VStack(spacing: 0) {
            topBar
            screen
        }
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onAppear { isFocused = true }
        .task { await viewModel.start() }
        .onKeyPress { press in handle(press) }
    }
 
    // MARK: - Top bar (tabs + shared clock)
 
    private var topBar: some View {
        HStack(spacing: 8) {
            ForEach(LaptopTab.allCases, id: \.self) { tab in
                tabLabel(for: tab)
            }
 
            Text("tab to switch")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color.gray)
                .padding(.leading, 8)
 
            Spacer()
 
            Text(timeText)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .frame(width: LaptopLayout.screenSize.width, height: LaptopLayout.topBarHeight)
        .background(Color(white: 0.12))
    }
 
    private func tabLabel(for tab: LaptopTab) -> some View {
        let isActive = viewModel.activeTab == tab
        let isDone = viewModel.isDone(tab)
 
        return Text(isDone ? "\(title(for: tab)) ✓" : title(for: tab))
            .font(.system(size: 16, weight: .semibold, design: .monospaced))
            .foregroundStyle(isActive ? Color.black : Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(isActive ? Color.white : Color.white.opacity(0.15), in: Capsule())
    }
 
    private func title(for tab: LaptopTab) -> String {
        switch tab {
        case .study:    return "Study"
        case .minigame: return "Minigame"
        }
    }
 
    private var timeText: String {
        let seconds = viewModel.secondsLeft
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
 
    // MARK: - Screen
 
    private var screen: some View {
        ZStack {
            TypingView(viewModel: viewModel.study)
                .opacity(viewModel.activeTab == .study ? 1 : 0)
 
            MinigameView(viewModel: viewModel.minigame, scene: minigameScene)
                .opacity(viewModel.activeTab == .minigame ? 1 : 0)
        }
        .frame(width: LaptopLayout.screenSize.width, height: LaptopLayout.screenSize.height)
        .clipped()
        .overlay { resultLabel }
    }
 
    @ViewBuilder
    private var resultLabel: some View {
        switch viewModel.state {
        case .won:
            banner("You made it!")
        case .lost:
            banner("Time's up!")
        case .preparing, .running:
            EmptyView()
        }
    }
 
    private func banner(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
    }
 
    // MARK: - Keyboard
 
    private func handle(_ press: KeyPress) -> KeyPress.Result {
        // Tab always belongs to the laptop. It never reaches either tab.
        if press.key == .tab {
            if press.phase == .down { viewModel.switchTab() }
            return .handled
        }
 
        switch viewModel.activeTab {
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
 
        if press.phase == .down { viewModel.move(direction) }
        return .handled
    }
 
    private func handleStudy(_ press: KeyPress) -> KeyPress.Result {
        if isBackspace(press) {
            viewModel.deleteLast()
            return .handled
        }
 
        guard press.modifiers.isDisjoint(with: [.command, .control]),
              press.characters.count == 1,
              let character = press.characters.first,
              character == " " || character.isLetter || character.isNumber
                || character.isPunctuation || character.isSymbol
        else { return .ignored }
 
        viewModel.type(character)
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
    LaptopView()
}
