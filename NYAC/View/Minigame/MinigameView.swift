//
//  MinigameView.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import SwiftUI
import SpriteKit

struct MinigameView: View {
    @StateObject private var viewModel: MinigameViewModel
    @State private var scene: MinigameScene
    @FocusState private var focused: Bool

    init() {
        let viewModel = MinigameViewModel()
        _viewModel = StateObject(wrappedValue: viewModel)
        _scene = State(initialValue: MinigameScene(viewModel: viewModel))
    }

    var body: some View {
        SpriteView(scene: scene)
            .allowsHitTesting(false)               // keep keyboard focus on this view, not the SKView
            .frame(width: MinigameLayout.size.width, height: MinigameLayout.size.height)
            .overlay(alignment: .topLeading) { timerLabel }
            .overlay { resultLabel }
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onAppear { focused = true }
            .onKeyPress(phases: .down) { press in handle(press) }
    }

    // MARK: - HUD

    private var timerLabel: some View {
        Text("\(viewModel.secondsLeft)")
            .font(.system(size: 22, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.6), in: Capsule())
            .padding(10)
    }

    @ViewBuilder
    private var resultLabel: some View {
        if case .ended(let outcome) = viewModel.state {
            Text(message(for: outcome))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func message(for outcome: Outcome) -> String {
        switch outcome {
        case .won:      return "You made it!"
        case .hitByCar: return "Splat!"
        case .drowned:  return "Splash!"
        case .timeUp:   return "Time's up!"
        }
    }

    // MARK: - Input (WASD or arrow keys, one hop per key press)

    private func handle(_ press: KeyPress) -> KeyPress.Result {
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
        viewModel.move(direction)
        return .handled
    }
}

