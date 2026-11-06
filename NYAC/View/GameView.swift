//
//  GameView.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import SwiftUI
import SpriteKit

/// The game screen. The head-tracking scene fills the whole screen with the far layer,
/// and the laptop floats in front of it as the near layer. Debug panel and camera preview sit on top
/// and each has its own on/off switch.
///
/// Everything about the run itself lives in GameViewModel: this view only shows it and starts it.
struct GameView: View {
    @State private var game: GameViewModel

    /// Called when the player leaves the game over screen. For now that means starting a new run.
    private let onRestart: () -> Void

    init(settings: GameSettings, onRestart: @escaping () -> Void) {
        self.onRestart = onRestart
        _game = State(initialValue: GameViewModel(settings: settings))
    }

    var body: some View {
        ZStack {
            // Far layer. Clicks pass through it so the keyboard stays with the laptop.
            SpriteView(scene: game.peek.scene)
                .allowsHitTesting(false)

            // Near layer: the laptop, moved every frame by the scene's parallax.
            LaptopLayer(scene: game.peek.scene, game: game)
        }
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) { controls }
        .overlay(alignment: .topTrailing) {
            if game.settings.showsCameraPiP {
                CameraPiPView(viewModel: game.peek, settings: game.settings)
                    .padding()
                    .focusable(false)
            }
        }
        // Last, so it sits in front of everything: the finished game stays visible behind it, dimmed.
        .overlay {
            if let content = game.gameOverContent {
                GameOverView(content: content, onBackToLobby: onRestart)
            }
        }
        .task { await game.start() }
        .onDisappear { game.stop() }
    }

    // MARK: - Overlays

    /// The two switches are always visible, so a hidden panel can always be brought back.
    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Toggle("Debug", isOn: Bindable(game.settings).showsDebugPanel)
                Toggle("Camera", isOn: Bindable(game.settings).showsCameraPiP)
            }
            .toggleStyle(.button)

            // Outside the debug panel on purpose: this has to stay readable when the panel is hidden.
            if game.peek.cameraDenied {
                Text("Camera access denied. Allow it in System Settings > Privacy & Security > Camera.")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .frame(maxWidth: 260, alignment: .leading)
            }

            if game.settings.showsDebugPanel {
                DebugPanelView(viewModel: game.peek, settings: game.settings)
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
    GameView(settings: GameSettings(), onRestart: {})
}
