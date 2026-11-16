//
//  MenuView.swift
//  NYAC
//
//  Created by Vrz on 17/11/26.
//

import SwiftUI
import SpriteKit

/// The main screen: the classroom (MenuScene) fills the screen, and the page for the current screen (the lobby or its
/// settings) is drawn on the board, moving with it.
///
/// RootView shows this view for both the lobby and the settings, so going from one to the other only swaps the page
/// on the board: the scene stays, and the parallax carries on without a break.
struct MenuView: View {
    let app: AppViewModel

    var body: some View {
        ZStack {
            // The room. Clicks pass through it, the page on the board is what the player uses.
            SpriteView(scene: app.menuScene)
                .allowsHitTesting(false)

            BoardPageLayer(scene: app.menuScene) { page }
        }
        .background(Color.white)
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) { cameraWarning }
    }

    // MARK: - Pages

    @ViewBuilder
    private var page: some View {
        switch app.screen {
        case .settings:
            BoardSettingsView(settings: app.settings, peek: app.peek, onBack: { app.backToLobby() })
        default:
            LobbyView(app: app)
        }
    }

    /// The camera warning in the top left corner, only while it applies. Without the camera there is no parallax,
    /// and the player has to know why.
    @ViewBuilder
    private var cameraWarning: some View {
        if app.peek.cameraDenied {
            Text("Camera access denied. Allow it in System Settings > Privacy & Security > Camera.")
                .font(.callout)
                .foregroundStyle(.red)
                .frame(maxWidth: 260, alignment: .leading)
                .padding()
                .focusable(false)
        }
    }
}

/// Puts the page on the board. The page is laid out in design units (the size of `MenuLayout.contentFrame`), scaled by
/// the same amount as the room, and moved with the board every frame. The closure re-runs on every screen refresh, but all
/// it applies is a scale and an offset: the page itself is built once, outside, and keeps its state in the view models.
private struct BoardPageLayer<Page: View>: View {
    let scene: MenuScene
    let page: Page

    init(scene: MenuScene, @ViewBuilder page: () -> Page) {
        self.scene = scene
        self.page = page()
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = ClassroomLayout.scale(fitting: geometry.size)
            let area = MenuLayout.contentFrame

            TimelineView(.animation) { _ in
                page
                    .frame(width: area.width, height: area.height)
                    .scaleEffect(scale)
                    // SpriteKit's y points up, SwiftUI's down, hence the minus signs on y.
                    .position(x: geometry.size.width / 2 + area.midX * scale + scene.boardShift.x,
                              y: geometry.size.height / 2 - area.midY * scale - scene.boardShift.y)
            }
        }
    }
}

#Preview {
    MenuView(app: AppViewModel())
        .frame(width: 1000, height: 650)
}
