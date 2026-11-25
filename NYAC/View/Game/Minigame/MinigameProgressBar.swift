//
//  MinigameProgressBar.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//

import SwiftUI

/// A thin bar that shows how far along the level the chicken is, with the percentage in the middle.
/// Black background, green fill growing from the left, white text.
struct MinigameProgressBar: View {

    /// 0 on the start row, 1 on the finish row.
    let progress: Double

    static let height: CGFloat = 20

    // Retro arcade palette pulled directly from your game's high-contrast colors
    private let trackColor = Color(red: 0.10, green: 0.10, blue: 0.12)
    private let fillColor = Color(red: 1.0, green: 0.78, blue: 0.0) // Taxi gold/amber (stands out against both road & grass)
    private let fillShadowColor = Color(red: 0.85, green: 0.55, blue: 0.0) // Flat 2-tone pixel shading

    var body: some View {
        let clamped = min(max(progress, 0), 1)

        ZStack {
            // 1. Flat dark track
            Rectangle()
                .fill(trackColor)

            // 2. Sharp, flat-shaded progress fill
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(fillColor)
                    // Hard-edged bottom pixel shade (no gradient)
                    Rectangle()
                        .fill(fillShadowColor)
                        .frame(height: 4)
                }
                .frame(width: geometry.size.width * clamped)
                .animation(.easeOut(duration: 0.12), value: clamped)
            }

            // 3. Double pixel-art border: white inner frame + crisp black outer frame
            Rectangle()
                .strokeBorder(.white, lineWidth: 2)
                .padding(2)

            Rectangle()
                .strokeBorder(.black, lineWidth: 2)

            // 4. Crisp arcade-style text with a hard 1px drop shadow (zero blur)
            Text("\(Int((clamped * 100).rounded()))%")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                .shadow(color: .black, radius: 0, x: -1, y: -1)
        }
        .frame(height: Self.height)
        // Hard unblurred offset shadow to lift it off the road like a retro UI box
        .background(
            Rectangle()
                .fill(.black.opacity(0.65))
                .offset(x: 3, y: 3)
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        MinigameProgressBar(progress: 0)
        MinigameProgressBar(progress: 0.43)
        MinigameProgressBar(progress: 1)
    }
    .frame(width: 600)
    .padding()
}
