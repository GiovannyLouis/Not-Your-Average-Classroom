//
//  PaperPalette.swift
//  NYAC
//
//  Created by Vrz on 27/11/26.
//

import SwiftUI

/// The colors of the paper-cutout look: off-white paper, a near-black marker, and a white rim where the scissors cut.
enum PaperPalette {
    /// The marker: the outline of every piece, and all the text on paper.
    static let ink = Color(red: 0.11, green: 0.10, blue: 0.10)

    /// Text on paper that matters less (a hint, a note).
    static let inkSoft = ink.opacity(0.6)

    /// The thin white margin around a piece, where it was cut out of its sheet.
    static let scissorRim = Color(red: 0.98, green: 0.97, blue: 0.95)

    /// The big cards: the game over screen, the in-game menu and settings.
    static let cardFill = Color(red: 0.95, green: 0.94, blue: 0.91)

    /// The small pieces: boxes (the stats, the HUD) and the pickers.
    static let boxFill = Color(red: 0.97, green: 0.96, blue: 0.94)

    static let buttonFill = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let buttonPressed = Color(red: 0.90, green: 0.88, blue: 0.84)

    /// A finished objective (its text and its checkbox). Darker than a bright green, so it can be read on paper.
    static let done = Color(red: 0.12, green: 0.55, blue: 0.22)
}
