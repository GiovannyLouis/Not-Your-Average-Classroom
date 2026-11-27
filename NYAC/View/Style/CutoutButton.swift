//
//  CutoutButton.swift
//  NYAC
//
//  Created by Vrz on 27/11/26.
//

import SwiftUI

/// The button used everywhere in the game: a hand-cut paper tag with a marker outline. It clicks when it is pressed.
///
/// By default it is as big as its title needs, with the title in the 18 point button font. For a bigger button (the ones on
/// the board) pass a bigger `fontSize`, and a `size` when it has to be an exact size. The paper look grows with the font,
/// so a big button has the same look as a small one: its outline, rim, snipped corners and shadow all scale with it.
struct CutoutButton: View {
    let title: String
    var fontSize: CGFloat = CutoutButton.baseFontSize
    /// An exact size for the button. When it is nil, the button is as big as its title, plus the padding.
    var size: CGSize? = nil
    let action: () -> Void

    /// The font size the look is made for. A bigger or smaller `fontSize` scales everything by the same amount.
    static let baseFontSize: CGFloat = 18

    /// The space around the title at the base size, when the button has no exact size.
    private static let horizontalPadding: CGFloat = 36
    private static let verticalPadding: CGFloat = 12

    var body: some View {
        let scale = fontSize / Self.baseFontSize

        Button {
            SoundService.shared.play(.click)
            action()
        } label: {
            if let size {
                titleText
                    .frame(width: size.width, height: size.height)
            } else {
                titleText
                    .padding(.horizontal, Self.horizontalPadding * scale)
                    .padding(.vertical, Self.verticalPadding * scale)
            }
        }
        .buttonStyle(CutoutButtonStyle(scale: scale))
    }

    private var titleText: some View {
        Text(title)
            .font(UIFont.bold(size: fontSize))
            .foregroundStyle(PaperPalette.ink)
    }
}

/// The paper behind a button's title, and what it does when pressed: it darkens, shrinks a little and sinks into the page.
struct CutoutButtonStyle: ButtonStyle {
    /// 1 for the base button, bigger for a bigger one (see `CutoutButton`).
    var scale: CGFloat = 1

    /// Every button has the same cut.
    private static let seed = 43

    func makeBody(configuration: Configuration) -> some View {
        let cut = PaperWeight.button.scaled(by: scale)

        configuration.label
            .background(
                HandCutSurface(
                    seed: Self.seed,
                    fill: configuration.isPressed ? PaperPalette.buttonPressed : PaperPalette.buttonFill,
                    weight: weight(pressed: configuration.isPressed)
                )
            )
            .contentShape(HandCutRectShape(seed: Self.seed, cornerCut: cut.cornerCut, wobble: cut.wobble))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .offset(y: configuration.isPressed ? 2 * scale : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }

    /// The look of the paper. Pressed, its shadow almost goes away: the paper lies flat on the page.
    private func weight(pressed: Bool) -> PaperWeight {
        var weight = PaperWeight.button.scaled(by: scale)
        if pressed {
            weight.shadowRadius *= 0.2
        }
        return weight
    }
}

#Preview("Buttons") {
    VStack(spacing: 24) {
        CutoutButton(title: "Back to Lobby") {}
        CutoutButton(title: "Settings", fontSize: 30, size: CGSize(width: 270, height: 80)) {}
        CutoutButton(title: "Start", fontSize: 44, size: CGSize(width: 410, height: 120)) {}
    }
    .padding(60)
    .background(Color.gray)
}
