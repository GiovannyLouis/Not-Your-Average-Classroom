//
//  BoardButton.swift
//  NYAC
//
//  Created by Vrz on 17/11/26.
//

import SwiftUI
import AppKit

// The pieces the pages on the board are made of. Their sizes are in design units (see MenuLayout), the page is scaled as a whole.

/// The game's button (CutoutButton) at the size of the board: "Start" and "Settings" are the same button in two sizes.
/// Its look grows with `fontSize`, so a big button has the same cut paper as a small one. It clicks when it is pressed.
struct BoardButton: View {
    let title: String
    let size: CGSize
    let fontSize: CGFloat
    let action: () -> Void

    var body: some View {
        CutoutButton(title: title, fontSize: fontSize, size: size, action: action)
    }
}

/// Text in the title's lettering: the game's title font (UIFont.title). The real lettering may be a picture later,
/// which is what BoardGameTitle already looks for, and this is also what the page titles use.
struct BoardTitleText: View {
    let text: String
    var size: CGFloat = MenuLayout.titleFontSize

    var body: some View {
        Text(text)
            .font(UIFont.title(size: size))
            .multilineTextAlignment(.center)
            .foregroundStyle(.black)
            .fixedSize()
    }
}

/// The game's title. Its picture (named `MenuLayout.titleAssetName`) when the project has one, text until then.
struct BoardGameTitle: View {
    var body: some View {
        Group {
            if let image = NSImage(named: NSImage.Name(MenuLayout.titleAssetName)) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                BoardTitleText(text: "Not Your Average\nClassroom")
            }
        }
        .frame(width: MenuLayout.titleSize.width, height: MenuLayout.titleSize.height)
        .rotationEffect(.degrees(MenuLayout.titleRotation))
    }
}

/// A slider in the style of the board: an outlined track that fills in black, and a black knob.
/// The system's slider is too small once the page is drawn in design units, and it would not look drawn by hand.
struct BoardSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>

    private let knob: CGFloat = 50
    private let track: CGFloat = 22

    var body: some View {
        GeometryReader { geometry in
            let travel = max(geometry.size.width - knob, 1)
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let knobX = min(max(fraction, 0), 1) * travel

            ZStack(alignment: .leading) {
                Capsule()
                    .stroke(.black, lineWidth: 5)
                    .frame(height: track)
                Capsule()
                    .fill(.black)
                    .frame(width: knobX + knob / 2, height: track)
                Circle()
                    .fill(.black)
                    .frame(width: knob, height: knob)
                    .offset(x: knobX)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let position = min(max((drag.location.x - knob / 2) / travel, 0), 1)
                        value = range.lowerBound + position * (range.upperBound - range.lowerBound)
                    }
            )
        }
        .frame(height: knob)
    }
}
