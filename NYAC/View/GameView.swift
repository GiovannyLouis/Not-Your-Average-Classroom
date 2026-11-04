//
//  GameView.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import SwiftUI
import SpriteKit

/// Root of the game. The head-tracking scene fills the whole screen with the far layer,
/// and the laptop floats in front of it as the near layer. Debug panel and camera preview sit on top
/// and each has its own on/off switch.
struct GameView: View {
    @State private var viewModel: PeekViewModel
    @State private var laptop: LaptopViewModel

    init() {
        // The laptop owns the lecturer (it decides what being seen means); the peek scene only draws it.
        let laptop = LaptopViewModel()
        _laptop = State(initialValue: laptop)
        _viewModel = State(initialValue: PeekViewModel(lecturer: laptop.lecturer))
    }

    var body: some View {
        ZStack {
            // Far layer. Clicks pass through it so the keyboard stays with the laptop.
            SpriteView(scene: viewModel.scene)
                .allowsHitTesting(false)

            // Near layer: the laptop, moved every frame by the scene's parallax.
            LaptopLayer(scene: viewModel.scene, laptop: laptop)
        }
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) { controls }
        .overlay(alignment: .topTrailing) {
            if viewModel.showsCameraPiP {
                CameraPiPView(viewModel: viewModel)
                    .padding()
                    .focusable(false)
            }
        }
        .background(FullScreenWindow())
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - Overlays

    /// The two switches are always visible, so a hidden panel can always be brought back.
    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Toggle("Debug", isOn: Bindable(viewModel).showsDebugPanel)
                Toggle("Camera", isOn: Bindable(viewModel).showsCameraPiP)
            }
            .toggleStyle(.button)

            // Outside the debug panel on purpose: this has to stay readable when the panel is hidden.
            if viewModel.cameraDenied {
                Text("Camera access denied. Allow it in System Settings > Privacy & Security > Camera.")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .frame(maxWidth: 260, alignment: .leading)
            }

            if viewModel.showsDebugPanel {
                DebugPanelView(viewModel: viewModel)
            }
        }
        .padding()
        .focusable(false)
    }
}

/// Puts the laptop wherever the scene says the near layer is. The closure re-runs on every screen refresh,
/// but all it applies is one offset: LaptopView's init is cheap and all its state lives in `laptop`.
private struct LaptopLayer: View {
    let scene: ParallaxScene
    let laptop: LaptopViewModel

    var body: some View {
        TimelineView(.animation) { _ in
            LaptopView(viewModel: laptop)
                .offset(x: scene.wallOffset.x, y: -scene.wallOffset.y)   // SpriteKit's y points up, SwiftUI's down
        }
    }
}

#Preview {
    GameView()
}
