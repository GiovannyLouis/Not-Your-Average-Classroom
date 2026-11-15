//
//  MinigameLayout.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation

/// Point sizes live in the view layer. The model only knows about cells.
enum MinigameLayout {
    static let cellSize: CGFloat = 88
    /// How many rows of the field the laptop screen shows at once. This sets the laptop's height too (LaptopLayout).
    static let visibleRows = 8

    static var size: CGSize {
        CGSize(width: CGFloat(MinigameConfig.columns) * cellSize,
               height: CGFloat(visibleRows) * cellSize)
    }
}
