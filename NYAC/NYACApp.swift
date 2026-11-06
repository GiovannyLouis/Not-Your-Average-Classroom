//
//  NYACApp.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import SwiftUI

import SwiftUI

@main
struct NYACApp: App {
    /// Lives as long as the app does, so the player's settings carry over from one run to the next.
    @State private var settings = GameSettings()

    /// Changing this throws the current game away and builds a fresh one (see `.id` below).
    @State private var runID = UUID()

    var body: some Scene {
        WindowGroup {
            GameView(settings: settings, onRestart: { runID = UUID() })
                .id(runID)
                .background(FullScreenWindow())     // the whole app is full screen, whichever screen is showing
        }
        .windowResizability(.contentSize)
    }
}
