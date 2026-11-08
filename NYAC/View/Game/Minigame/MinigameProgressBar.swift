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

    /// Thin on purpose: just enough to read the percentage.
    static let height: CGFloat = 16

    var body: some View {
        let clamped = min(max(progress, 0), 1)

        ZStack {
            Rectangle()
                .fill(.black)

            GeometryReader { geometry in
                Rectangle()
                    .fill(.green)
                    .frame(width: geometry.size.width * clamped)
            }

            Text("\(Int((clamped * 100).rounded()))%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(height: Self.height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
