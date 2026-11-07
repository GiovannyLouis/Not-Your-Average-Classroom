//
//  GameView.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import SwiftUI
import SpriteKit

/// The game screen. The head-tracking scene fills the whole screen with the far layer,
/// and the laptop floats in front of it as the near layer. The countdown, the Escape menu and the game over
/// screen are laid over it, each one only while it applies.
///
/// Everything about the run itself lives in GameViewModel: this view only shows it and starts it.
struct GameView: View {
    /// The run being played. The app makes a fresh one for every Start, so this view never needs resetting.
    let game: GameViewModel

    var body: some View {
        ZStack {
            // Far layer. Clicks pass through it so the keyboard stays with the laptop.
            SpriteView(scene: game.peek.scene)
                .allowsHitTesting(false)

            // Near layer: the laptop, moved every frame by the scene's parallax.
            LaptopLayer(scene: game.peek.scene, game: game)
        }
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) { cameraWarning }
        .overlay {
            if let number = game.countdown {
                CountdownView(number: number)
            }
        }
        // The menu and the game over screen come last, so they sit in front of everything:
        // the game stays visible behind them, dimmed.
        .overlay {
            if game.menu != .closed {
                GameMenuView(game: game)
            }
        }
        .overlay {
            if let content = game.gameOverContent {
                GameOverView(content: content, onBackToLobby: { game.backToLobby() })
            }
        }
        .task { await game.start() }
        .onDisappear { game.stop() }
    }

    // MARK: - Overlays

    /// Always visible when it applies: without the camera there is no peeking, and the player has to know why.
    @ViewBuilder
    private var cameraWarning: some View {
        if game.peek.cameraDenied {
            Text("Camera access denied. Allow it in System Settings > Privacy & Security > Camera.")
                .font(.callout)
                .foregroundStyle(.red)
                .frame(maxWidth: 260, alignment: .leading)
                .padding()
                .focusable(false)
        }
    }
}

/// Puts the laptop wherever the scene says the near layer is. The closure re-runs on every screen refresh,
/// but all it applies is one offset: LaptopView's init is cheap and all its state lives in `game`.
private struct LaptopLayer: View {
    let scene: ParallaxScene
    let game: GameViewModel

    var body: some View {
        TimelineView(.animation) { _ in
            LaptopView(game: game)
                .offset(x: scene.wallOffset.x, y: -scene.wallOffset.y)   // SpriteKit's y points up, SwiftUI's down
        }
    }
}

#Preview {
    GameView(game: GameViewModel(settings: GameSettings()))
}
