//
//  NYACApp.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import SwiftUI

@main
struct NYACApp: App {
    var body: some Scene {
        WindowGroup {
            MinigameView()
        }
        .windowResizability(.contentSize)
    }
}
