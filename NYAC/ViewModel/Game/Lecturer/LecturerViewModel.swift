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
    /// Turning it off while he is walking also stops his footsteps.
    @ObservationIgnored var isActive = false {
        didSet {
            if !isActive { stopFootsteps() }
        }
    }

    /// Called each time the lecturer starts or stops walking. The game uses it to check whether the player just got caught.
    @ObservationIgnored var onStateChanged: (() -> Void)?

    /// Seconds spent in the current stay or walk. Changes every frame, so it is not observed.
    @ObservationIgnored private var timeInPhase: TimeInterval = 0

    /// Where the lecturer is on LecturerConfig.debugRoute, when there is one.
    @ObservationIgnored private var routeIndex = 0

    /// The footsteps' sound. His footsteps are his, so he plays them himself.
    @ObservationIgnored private let sound: SoundService

    /// For SoundConfig.FootstepsPlayback.perStep: how many steps of the current walk have made their sound already.
    @ObservationIgnored private var stepsPlayed = 0

    init(sound: SoundService = .shared) {
        self.sound = sound

        // The lecturer starts standing at a random spot (or at the start of the debug route).
        state = .staying(LecturerConfig.debugRoute?.first ?? LecturerSpot.allCases.randomElement() ?? .b)
    }

    // MARK: - Game loop (the scene calls this every frame)

    func update(deltaTime: TimeInterval) {
        guard isActive else { return }
        timeInPhase += min(deltaTime, 0.1)       // a long frame must not skip a whole phase

        switch state {
        case .staying(let spot):
            guard timeInPhase >= LecturerConfig.stayDuration else { return }
            timeInPhase -= LecturerConfig.stayDuration
            let next = nextSpot(after: spot)
            state = .moving(from: spot, to: next)
            startFootsteps()
            onStateChanged?()

        case .moving(_, let destination):
            playStepsThatAreDue()
            guard timeInPhase >= LecturerConfig.moveDuration else { return }
            timeInPhase -= LecturerConfig.moveDuration
            state = .staying(destination)
            stopFootsteps()
            onStateChanged?()
        }
    }

    // MARK: - Footsteps
    // He walks from one spot to another, whether or not the player can see him (between A and D he cannot, and the
    // footsteps are how the player knows he is on the move). How the sound is played is SoundConfig.footsteps.

    /// The walk has just started.
    private func startFootsteps() {
        switch SoundConfig.footsteps {
        case .loop:
            sound.startLoop(.footsteps)
        case .perStep:
            stepsPlayed = completedSteps
        }
    }

    /// The walk is over (he arrived, or the run ended).
    private func stopFootsteps() {
        if SoundConfig.footsteps == .loop {
            sound.stopLoop(.footsteps, fadeOut: SoundConfig.footstepsFadeOut)
        }
    }

    /// For `.perStep`: plays the sound once for every step that has touched the ground since the last frame.
    /// His bounce (LecturerWalkLayout.stepLift) touches the ground whenever seconds * stepsPerSecond is a whole number,
    /// so that is the moment of each step, the one at the very end of the walk (when he arrives) included.
    private func playStepsThatAreDue() {
        guard SoundConfig.footsteps == .perStep, completedSteps > stepsPlayed else { return }
        stepsPlayed = completedSteps
        sound.play(.footsteps)
    }

    /// How many steps of the current walk have touched the ground so far.
    private var completedSteps: Int {
        Int(min(timeInPhase, LecturerConfig.moveDuration) * LecturerConfig.stepsPerSecond)
    }

    /// Where the lecturer walks to from this spot: a random neighbor, or the next spot of the debug route.
    private func nextSpot(after spot: LecturerSpot) -> LecturerSpot {
        if let route = LecturerConfig.debugRoute, !route.isEmpty {
            routeIndex = (routeIndex + 1) % route.count
            return route[routeIndex]
        }
        return spot.neighbors.randomElement() ?? spot
    }
}
