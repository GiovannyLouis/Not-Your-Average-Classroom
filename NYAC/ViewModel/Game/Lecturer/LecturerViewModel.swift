//
//  LecturerViewModel.swift
//  NYAC
//
//  Created by Vrz on 04/11/26.
//

import Foundation
import Observation

/// Where the lecturer is and what they are doing: stay 5 seconds, walk 5 seconds to a random neighbor, repeat.
///
/// This view model only moves the lecturer. What being at a given spot means for the player
/// (getting caught) is decided by whoever owns it, which is the game.
@MainActor
@Observable
final class LecturerViewModel {

    private(set) var state: LecturerState

    /// How far through the current walk the lecturer is, 0...1 (always 0 while standing still).
    /// The top view reads this every frame to place the lecturer between two spots.
    var progress: Double {
        guard case .moving = state else { return 0 }
        return min(timeInPhase / LecturerConfig.moveDuration, 1)
    }

    /// The game turns this on when the run starts and off when it ends. The lecturer only walks while it is on.
    @ObservationIgnored var isActive = false

    /// Called each time the lecturer starts or stops walking. The game uses it to check whether the player just got caught.
    @ObservationIgnored var onStateChanged: (() -> Void)?

    /// Seconds spent in the current stay or walk. Changes every frame, so it is not observed.
    @ObservationIgnored private var timeInPhase: TimeInterval = 0

    init() {
        // The lecturer starts standing at a random spot.
        state = .staying(LecturerSpot.allCases.randomElement() ?? .b)
    }

    // MARK: - Game loop (the scene calls this every frame)

    func update(deltaTime: TimeInterval) {
        guard isActive else { return }
        timeInPhase += min(deltaTime, 0.1)       // a long frame must not skip a whole phase

        switch state {
        case .staying(let spot):
            guard timeInPhase >= LecturerConfig.stayDuration else { return }
            timeInPhase -= LecturerConfig.stayDuration
            let next = spot.neighbors.randomElement() ?? spot
            state = .moving(from: spot, to: next)
            onStateChanged?()

        case .moving(_, let destination):
            guard timeInPhase >= LecturerConfig.moveDuration else { return }
            timeInPhase -= LecturerConfig.moveDuration
            state = .staying(destination)
            onStateChanged?()
        }
    }
}
