//
//  PaperStyle.swift
//  NYAC
//
//  Created by Vrz on 27/11/26.
//

import SwiftUI

extension View {
    /// The off-white hand-cut card with a thick marker outline that every overlay screen sits on
    /// (game over, the in-game menu and settings).
    func cardStyle(width: CGFloat = 720) -> some View {
        self
            .foregroundStyle(PaperPalette.ink)
            .padding(.vertical, 32)
            .padding(.horizontal, 36)
            .frame(width: width)
            .background(HandCutSurface(seed: 7, fill: PaperPalette.cardFill, weight: .card))
    }

    /// A smaller piece of paper: a box for the stats of the game over screen, a grouped row of settings, a piece of the HUD.
    /// Give it its own `seed` when there are several next to each other, so that their edges are not the same.
    /// `weight` is `.box` by default, `.hud` for the pieces of the HUD.
    func cutoutBoxStyle(seed: Int = 19, weight: PaperWeight = .box) -> some View {
        self
            .background(HandCutSurface(seed: seed, fill: PaperPalette.boxFill, weight: weight))
    }
}

#Preview("Paper style") {
    VStack(spacing: 18) {
        Text("Menu")
            .font(UIFont.title(size: 44))
        Text("A card, two boxes and the buttons.")
            .font(UIFont.body(size: 18))

        HStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("Completion Time").font(UIFont.body(size: 17))
                Text("01:23").font(UIFont.bold(size: 26))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .cutoutBoxStyle(seed: 11)

            Text("04:59")
                .font(UIFont.bold(size: 24))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .cutoutBoxStyle(seed: 23, weight: .hud)
        }

        CutoutButton(title: "Settings") {}
        CutoutButton(title: "Start", fontSize: 30, size: CGSize(width: 270, height: 80)) {}
    }
    .cardStyle(width: 420)
    .padding(60)
    .background(Color.gray)
}
