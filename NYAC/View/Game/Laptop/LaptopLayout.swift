//
//  LaptopLayout.swift
//  NYAC
//
//  Created by Vrz on 30/10/26.
//

import Foundation

/// Point sizes live in the view layer.
enum LaptopLayout {
    /// The laptop screen is exactly as big as the minigame field; the study view fills the same frame.
    static var screenSize: CGSize { MinigameLayout.size }

    /// The whole laptop as one box. There is nothing on it but the screen, so it is the screen's size.
    /// The Peek scene uses this as the size of the laptop.
    static var size: CGSize { screenSize }
}
