//
//  PreparingView.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//


import SwiftUI

/// Shown in front of the game while it gets ready (the study text is being written). The countdown takes over once it is done.
struct PreparingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)

            VStack(spacing: 24) {
                ProgressView()
                    .controlSize(.large)
                    .environment(\.colorScheme, .dark)

                Text("Preparing…")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PreparingView()
        .frame(width: 1000, height: 650)
}
