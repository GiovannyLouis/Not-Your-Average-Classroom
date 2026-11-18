//
//  TypingLayout.swift
//  NYAC
//
//  Created by Vrz on 18/11/26.
//

import Foundation

/// Point sizes and timings of the Study screen.
enum TypingLayout {

    // MARK: - The wrong-key shake

    /// When a wrong character is typed, the text shakes sideways for this many seconds.
    static let shakeDuration: TimeInterval = 0.3

    /// How far the text swings to each side at the start of the shake, in points. It dies down to nothing by the end.
    /// Keep it under the screen's padding (60), or the text would run out of the screen.
    static let shakeTravel: CGFloat = 8

    /// How many times the text swings from one side to the other and back during the shake.
    /// It has to be a whole number, so that the text comes to rest exactly where it started.
    static let shakeCycles: CGFloat = 3
}
