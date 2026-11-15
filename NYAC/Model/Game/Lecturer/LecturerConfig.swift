//
//  LecturerConfig.swift
//  NYAC
//
//  Created by Vrz on 04/11/26.
//

import Foundation

enum LecturerConfig {
    /// How long the lecturer stands at a spot before walking off.
    static let stayDuration: TimeInterval = 5

    /// How long the walk to the next spot takes, whatever the distance.
    static let moveDuration: TimeInterval = 5

    /// How fast the lecturer's footsteps go while he walks, in steps per second. Every step lifts him up and down once
    /// (how high is LecturerWalkLayout.stepHeight). The footstep sound will follow this tempo too, and it is the same
    /// for every walk, wherever he is going.
    static let stepsPerSecond: Double = 2

    /// For testing the walks: when this is set, the lecturer starts at the first spot of the route and then visits the
    /// spots one after the other (and starts over at the end), instead of picking a random neighbor each time.
    /// Every two spots in a row, the last one and the first one included, must be neighbors.
    /// This one goes through all six walks you can see (B to A, A to B, B to C, C to D, D to C, C to B):
    ///     [.b, .a, .b, .c, .d, .c]
    /// Leave it nil to play normally.
    static let debugRoute: [LecturerSpot]? = nil
}
