//
//  FullScreenWindow.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import SwiftUI
import AppKit

/// Attach with `.background(FullScreenWindow())`. When the window appears it goes into macOS full screen, once.
/// If the player leaves full screen later, it stays out (it never forces them back in).
struct FullScreenWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        FullScreenRequestView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// An invisible view whose only job is to find the window it ends up in.
private final class FullScreenRequestView: NSView {
    private var didRequest = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard !didRequest, let window else { return }
        didRequest = true

        window.collectionBehavior.insert(.fullScreenPrimary)

        // Wait a beat so the window has finished appearing before it animates into full screen.
        Task { @MainActor [weak window] in
            guard let window, !window.styleMask.contains(.fullScreen) else { return }
            window.toggleFullScreen(nil)
        }
    }
}
