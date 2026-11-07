//
//  PillButton.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//


import SwiftUI

/// The outlined pill button used on every card (game over, in-game menu, settings).
struct PillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18))
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .overlay(Capsule().stroke(.black, lineWidth: 5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// The white card with a thick black outline that every overlay screen sits on.
    func cardStyle(width: CGFloat = 720) -> some View {
        self
            .foregroundStyle(.black)
            .padding(.vertical, 28)
            .padding(.horizontal, 32)
            .frame(width: width)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.black, lineWidth: 5))
    }
}
