//
//  PaperWeight.swift
//  NYAC
//
//  Created by Vrz on 27/11/26.
//

import SwiftUI

/// How heavy a hand-cut piece of paper looks: the thickness of its outline, its white rim, how far its corners are snipped,
/// how wobbly its edges are, and its shadow. This is the one place to make a kind of piece heavier or lighter.
///
/// Every number is in points for a piece of normal size. `scaled(by:)` gives the same look for a smaller or bigger piece.
struct PaperWeight {
    /// The marker outline.
    var strokeWidth: CGFloat
    /// The white scissor-cut margin outside the outline.
    var cutoutRim: CGFloat
    /// How much each corner is snipped off.
    var cornerCut: CGFloat
    /// How far the edges stray from a straight line (up to this many points, different at every point).
    var wobble: CGFloat
    var shadowRadius: CGFloat
    var shadowOffset = CGSize(width: 2, height: 5)

    /// The same look, `factor` times as big (0.8 = a lighter piece for something small, 2 = for something twice as big).
    func scaled(by factor: CGFloat) -> PaperWeight {
        PaperWeight(strokeWidth: strokeWidth * factor,
                    cutoutRim: cutoutRim * factor,
                    cornerCut: cornerCut * factor,
                    wobble: wobble * factor,
                    shadowRadius: shadowRadius * factor,
                    shadowOffset: CGSize(width: shadowOffset.width * factor, height: shadowOffset.height * factor))
    }

    /// The big cards (game over, in-game menu and settings).
    static let card = PaperWeight(strokeWidth: 4.5, cutoutRim: 6, cornerCut: 10, wobble: 2.0, shadowRadius: 10)

    /// The boxes inside a card (the stats) and the pickers.
    static let box = PaperWeight(strokeWidth: 3.5, cutoutRim: 4, cornerCut: 8, wobble: 1.5, shadowRadius: 4)

    /// The buttons. The wider corner snip gives them a hand-trimmed pill / tag shape.
    static let button = PaperWeight(strokeWidth: 3.8, cutoutRim: 4, cornerCut: 14, wobble: 1.4, shadowRadius: 5)

    /// The pieces of the in-game HUD (the clock, the menu hint, the progress card). A bit lighter than a box,
    /// because they are small and sit on top of the game. Change the 0.8 to make all of them heavier or lighter.
    static let hud = PaperWeight.box.scaled(by: 0.8)
}

/// A paper rectangle with snipped corners and slightly wobbly edges, like cut out by hand.
/// `seed` decides how the wobble looks: the same seed always gives the same cut, and a different seed a different one,
/// so pieces next to each other do not look copied.
struct HandCutRectShape: Shape {
    let seed: Int
    var cornerCut: CGFloat = 10
    var wobble: CGFloat = 1.8

    func path(in rect: CGRect) -> Path {
        func jitter(_ index: Int) -> CGFloat {
            let v = sin(Double(seed * 97 + index * 31)) * 43758.5453
            let frac = v - floor(v)
            return CGFloat(frac * 2.0 - 1.0) * wobble
        }

        let left = rect.minX
        let right = rect.maxX
        let top = rect.minY
        let bottom = rect.maxY
        let cut = min(cornerCut, min(rect.width, rect.height) * 0.35)

        let points: [CGPoint] = [
            // Top-left snipped corner
            CGPoint(x: left + jitter(1), y: top + cut + jitter(2)),
            CGPoint(x: left + cut + jitter(3), y: top + jitter(4)),
            // Subtle mid-edge organic variation
            CGPoint(x: rect.midX, y: top + jitter(5)),
            // Top-right snipped corner
            CGPoint(x: right - cut + jitter(6), y: top + jitter(7)),
            CGPoint(x: right + jitter(8), y: top + cut + jitter(9)),
            // Right mid-edge
            CGPoint(x: right + jitter(10), y: rect.midY),
            // Bottom-right snipped corner
            CGPoint(x: right + jitter(11), y: bottom - cut + jitter(12)),
            CGPoint(x: right - cut + jitter(13), y: bottom + jitter(14)),
            // Bottom mid-edge
            CGPoint(x: rect.midX, y: bottom + jitter(15)),
            // Bottom-left snipped corner
            CGPoint(x: left + cut + jitter(16), y: bottom + jitter(17)),
            CGPoint(x: left + jitter(18), y: bottom - cut + jitter(19)),
            // Left mid-edge
            CGPoint(x: left + jitter(20), y: rect.midY)
        ]

        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

/// What sits behind a piece of paper: the white rim with its shadow, the paper itself, and the marker outline.
/// Cards, boxes and buttons are all this, with a different `weight`.
struct HandCutSurface: View {
    let seed: Int
    let fill: Color
    let weight: PaperWeight

    var body: some View {
        ZStack {
            // Outer white scissor-cut margin + subtle shadow
            HandCutRectShape(seed: seed, cornerCut: weight.cornerCut, wobble: weight.wobble)
                .fill(PaperPalette.scissorRim)
                .padding(-weight.cutoutRim)
                .shadow(color: .black.opacity(0.32),
                        radius: weight.shadowRadius,
                        x: weight.shadowOffset.width,
                        y: weight.shadowOffset.height)

            // Inner paper fill
            HandCutRectShape(seed: seed, cornerCut: weight.cornerCut, wobble: weight.wobble)
                .fill(fill)

            // Thick marker border
            HandCutRectShape(seed: seed, cornerCut: weight.cornerCut, wobble: weight.wobble)
                .stroke(
                    PaperPalette.ink,
                    style: StrokeStyle(
                        lineWidth: weight.strokeWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
        }
    }
}
