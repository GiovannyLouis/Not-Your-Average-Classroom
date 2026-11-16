//
//  LobbyView.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//

import SwiftUI

/// The main menu page, drawn on the board: the title and two buttons. The room behind it is MenuScene
/// (see MenuView), so this page only has what sits on the board, and it is laid out to fit inside `MenuLayout.contentFrame`.
struct LobbyView: View {
    let app: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            BoardGameTitle()

            BoardButton(title: "Start",
                        size: MenuLayout.startButtonSize,
                        fontSize: MenuLayout.startButtonFontSize) { app.startGame() }
                .padding(.top, 38)

            BoardButton(title: "Settings",
                        size: MenuLayout.smallButtonSize,
                        fontSize: MenuLayout.smallButtonFontSize) { app.openSettings() }
                .padding(.top, 26)
        }
        .padding(.bottom, 60)
    }
}

#Preview {
    MenuView(app: AppViewModel())
        .frame(width: 1000, height: 650)
}
