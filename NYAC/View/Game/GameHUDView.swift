//
//  GameHUDView.swift
//  NYAC
//
//  Created by Vrz on 15/11/26.
//

import SwiftUI

/// The HUD overlay: the menu hint and progress card in the top left, and the clock in the top right.
/// It is only there to be read: clicks and keys go straight through it.
struct GameHUDView: View {
    let game: GameViewModel

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                menuHint

                ProgressCardView(
                    items: game.checklist.map { objective in
                        ProgressCardView.Item(title: objective.title, isDone: game.isDone(objective))
                    },
                    isVisible: game.showsProgressCard
                )
            }

            Spacer()

            clock
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .focusable(false)
    }

    private var clock: some View {
        Text(game.timeText)
            .font(.system(size: 22, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.5), in: Capsule())
    }

    /// The opposite of the menu: shown while it is closed, gone while it is open (the menu says how to close it).
    /// It fades instead of leaving, so the progress card under it stays where it is.
    private var menuHint: some View {
        Text("Press Esc to open menu")
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.5), in: Capsule())
            .opacity(game.showsMenuHint ? 1 : 0)
    }
}

#Preview {
    let settings = GameSettings()
    GameHUDView(game: GameViewModel(settings: settings, peek: PeekViewModel(settings: settings)))
        .frame(width: 800, height: 400)
        .background(Color(white: 0.85))
}
