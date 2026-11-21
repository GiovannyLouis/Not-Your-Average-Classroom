//
//  LecturerConfig.swift
//  NYAC
//
//  Created by Vrz on 04/11/26.
//

import Foundation

enum LecturerConfig {
    /// How long the lecturer stands at a spot before walking off, in seconds. Every stay picks a new time in this range
    /// (any time in it is equally likely), so the player cannot learn his rhythm. Make both numbers the same, like 5...5,
    /// for a fixed time again.
    static let stayDurationRange: ClosedRange<TimeInterval> = 2...5

    /// How long a walk to the next spot takes, in seconds, whatever the distance. Every walk picks a new time in this range.
    /// The walk animation and the footsteps follow it (see `steps(inWalkOf:)`).
    static let moveDurationRange: ClosedRange<TimeInterval> = 4...6

    /// How fast the lecturer's footsteps go while he walks, in steps per second. Every step lifts him up and down once
    /// (how high is LecturerWalkLayout.stepHeight), and the footstep sound is played with each one.
    ///
    /// This is the tempo he aims for. Because a walk lasts a different time every time, each walk is given a whole number
    /// of steps (see `steps(inWalkOf:)`), so his last step always touches the ground right as he arrives. That moves the
    /// tempo of one walk a little (at most 0.5 step in the whole walk, about 6% at the shortest).
    static let stepsPerSecond: Double = 2

    /// A new stay time, from `stayDurationRange`.
    static func randomStayDuration() -> TimeInterval {
        TimeInterval.random(in: stayDurationRange)
    }

    /// A new walk time, from `moveDurationRange`.
    static func randomMoveDuration() -> TimeInterval {
        TimeInterval.random(in: moveDurationRange)
    }

    /// How many steps a walk of this many seconds has: as close to `stepsPerSecond` as a whole number of steps allows, and
    /// at least one. The bounce (LecturerWalkLayout.stepLift) and the footstep sound (LecturerViewModel) both use this,
    /// so the sound is always played at the moment the bounce touches the ground.
    static func steps(inWalkOf duration: TimeInterval) -> Int {
        max(1, Int((duration * stepsPerSecond).rounded()))
    }

    /// For testing the walks: when this is set, the lecturer starts at the first spot of the route and then visits the
    /// spots one after the other (and starts over at the end), instead of picking a random neighbor each time.
    /// Every two spots in a row, the last one and the first one included, must be neighbors.
    /// This one goes through all six walks you can see (B to A, A to B, B to C, C to D, D to C, C to B):
    ///     [.b, .a, .b, .c, .d, .c]
    /// Leave it nil to play normally.
    static let debugRoute: [LecturerSpot]? = nil
}
