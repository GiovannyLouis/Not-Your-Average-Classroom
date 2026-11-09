//
//  GameView.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import SwiftUI
import SpriteKit

/// The game screen. The head-tracking scene fills the whole screen with the far layer,
/// and the laptop floats in front of it as the near layer. The preparing screen, the countdown, the Escape menu
/// and the game over screen are laid over it, each one only while it applies.
///
/// Everything about the run itself lives in GameViewModel: this view only shows it and starts it.
struct GameView: View {
    /// The run being played. The app makes a fresh one for every Start, so this view never needs resetting.
    let game: GameViewModel

    var body: some View {
        ZStack {
            // Far layer. Clicks pass through it so the keyboard stays with the laptop.
            SpriteView(scene: game.parallaxScene)
                .allowsHitTesting(false)

            // Near layer: the laptop, moved every frame by the scene's parallax.
            LaptopLayer(scene: game.parallaxScene, game: game)
        }
        .ignoresSafeArea()
        .overlay {
            if game.isPreparing {
                PreparingView()
            } else if let number = game.countdown {
                CountdownView(number: number)
            }
        }
        .overlay(alignment: .topLeading) { topLeading }
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

    /// The notes in the top left corner: how to open the menu, and the camera warning when it applies.
    private var topLeading: some View {
        VStack(alignment: .leading, spacing: 10) {
            // The opposite of the menu: shown while it is closed, gone while it is open (the menu says how to close it).
            if game.showsMenuHint {
                Text("Press Esc to open menu")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5), in: Capsule())
            }

            // Without the camera there is no peeking, and the player has to know why.
            if game.peek.cameraDenied {
                Text("Camera access denied. Allow it in System Settings > Privacy & Security > Camera.")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .frame(maxWidth: 260, alignment: .leading)
            }
        }
        .padding()
        .focusable(false)
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
    let settings = GameSettings()
    GameView(game: GameViewModel(settings: settings, peek: PeekViewModel(settings: settings)))
}
