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
                    .padding(.top, 32)
                    .padding(.horizontal, 48)
                    .opacity(isWon ? 0 : 1)        // it has done its job once the run is won: fade it out
                    .animation(.easeOut(duration: MinigameLayout.progressFadeDuration), value: isWon)
            }   // inside the frame: the screen keeps its size
            .overlay { resultLabel }
    }

    // MARK: - HUD

    private var isWon: Bool { viewModel.state == .ended(.won) }

    /// The picture of how the run ended (win, hit, drown), over the world that keeps running.
    /// Until the project has that picture it is the text the game started with.
    @ViewBuilder
    private var resultLabel: some View {
        if case .ended(let outcome) = viewModel.state {
            ZStack {
                Color.black.opacity(0.3)
                
                if let size = MinigameLayout.outcomeImageSize(for: outcome) {
                    Image(MinigameLayout.outcomeAssetName(for: outcome))
                        .resizable()
                        .frame(width: size.width, height: size.height)
                } else {
                    Text(message(for: outcome))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                }
            }
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
