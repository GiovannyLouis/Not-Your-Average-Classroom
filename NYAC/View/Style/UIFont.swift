//
//  UIFont.swift
//  NYAC
//
//  Created by Vrz on 27/11/26.
//

import SwiftUI

/// The game's two typefaces, for every piece of text in the game: Marker Felt Wide for titles, Chalkboard SE for everything
/// else (both come with macOS). Use these instead of `.font(.system(...))`, so the whole game can be changed in one place.
///
/// The names have to be the fonts' PostScript names. A name that does not exist is not an error: SwiftUI quietly draws the
/// system font, so a typo shows up as text in the wrong font.
enum UIFont {
    static let titleName = "MarkerFelt-Wide"
    static let bodyName = "ChalkboardSE-Regular"
    static let boldName = "ChalkboardSE-Bold"

    /// Titles: the card titles, the big numbers.
    static func title(size: CGFloat) -> Font {
        .custom(titleName, size: size)
    }

    /// Everything that is read: messages, labels, hints.
    static func body(size: CGFloat) -> Font {
        .custom(bodyName, size: size)
    }

    /// Body text that has to stand out: buttons, numbers, the clock.
    static func bold(size: CGFloat) -> Font {
        .custom(boldName, size: size)
    }
}
