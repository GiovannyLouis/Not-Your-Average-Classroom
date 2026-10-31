//
//  LaptopLayout.swift
//  NYAC
//
//  Created by Vrz on 30/10/26.
//

import Foundation

/// Point sizes live in the view layer.
enum LaptopLayout {
    static let topBarHeight: CGFloat = 44

    /// The laptop screen is exactly as big as the minigame field; the study view fills the same frame.
    static var screenSize: CGSize { MinigameLayout.size }
}
