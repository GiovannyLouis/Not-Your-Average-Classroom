//
//  MinigameView.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import SwiftUI
import SpriteKit

/// Pure display: the game owns the clock, the laptop owns the keyboard and the scene.
struct MinigameView: View {
    @ObservedObject var viewModel: MinigameViewModel
    let scene: MinigameScene

    var body: some View {
        SpriteView(scene: scene)
            .allowsHitTesting(false)               // keyboard focus belongs to the laptop, not the SKView
            .frame(width: MinigameLayout.size.width, height: MinigameLayout.size.height)
            .overlay(alignment: .top) {
                MinigameProgressBar(progress: viewModel.progress)
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
            }   // inside the frame: the screen keeps its size
            .overlay { resultLabel }
    }

    // MARK: - HUD

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
        }
    }
}


