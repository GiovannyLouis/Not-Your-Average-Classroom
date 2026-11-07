//
//  LobbyView.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//

import SwiftUI

/// The main menu: the title and two buttons.
struct LobbyView: View {
    let app: AppViewModel

    var body: some View {
        VStack(spacing: 110) {
            Text("Not Your Average Classroom")
                .font(.system(size: 64, design: .serif))
                .foregroundStyle(.black)

            VStack(spacing: 24) {
                LobbyButton(title: "Start") { app.startGame() }
                LobbyButton(title: "Settings") { app.openSettings() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

private struct LobbyButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .frame(width: 260, height: 56)
                .background(Color(red: 0.31, green: 0.37, blue: 0.68), in: RoundedRectangle(cornerRadius: 10))
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LobbyView(app: AppViewModel())
        .frame(width: 1000, height: 650)
}
