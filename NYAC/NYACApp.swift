//
//  NYACApp.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import SwiftUI

@main
struct NYACApp: App {
    /// Owns the current screen, the player's settings and the camera for as long as the app is open.
    @State private var app = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(app: app)
                .background(FullScreenWindow())     // the whole app is full screen, whichever screen is showing
                .task { await app.start() }         // the camera opens with the app, not with a screen
                .onDisappear { app.stop() }
        }
        .windowResizability(.contentSize)
    }
}
