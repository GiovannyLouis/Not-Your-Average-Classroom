//
//  NYACApp.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import SwiftUI

@main
struct NYACApp: App {
    /// Owns the current screen and the player's settings for as long as the app is open.
    @State private var app = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(app: app)
                .background(FullScreenWindow())     // the whole app is full screen, whichever screen is showing
        }
        .windowResizability(.contentSize)
    }
}
