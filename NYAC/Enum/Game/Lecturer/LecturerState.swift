//
//  LecturerState.swift
//  NYAC
//
//  Created by Vrz on 04/11/26.
//


/// What the lecturer is doing right now: standing still at a spot, or walking to a neighbor.
enum LecturerState: Equatable {
    case staying(LecturerSpot)
    case moving(from: LecturerSpot, to: LecturerSpot)

    /// True when playing the game right now would get the player caught: the lecturer is standing at an
    /// unsafe spot (A or D), or is walking between two unsafe spots (A to D, or D to A).
    /// Walking between a safe and an unsafe spot (say B to A) is not dangerous until the lecturer arrives.
    var canCatchPlayer: Bool {
        switch self {
        case .staying(let spot):
            return !spot.isSafe
        case .moving(let from, let to):
            return !from.isSafe && !to.isSafe
        }
    }
}