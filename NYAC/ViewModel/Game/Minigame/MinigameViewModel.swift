//
//  MinigameViewModel.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation
import Combine

final class MinigameViewModel: ObservableObject {

    // Observed by SwiftUI (result label, progress bar). They change on a hop or a death, not every frame.
    @Published private(set) var state: MinigameState = .ready
    @Published private(set) var playerRow = 0

    // Read by the scene every frame. Deliberately not @Published: they change 60x a second.
    private(set) var rows: [Row] = []
    private(set) var playerX: CGFloat = 0          // in cells, may sit between cells on a log
    private(set) var levelVersion = 0              // bumps whenever a new level is generated

    /// The way the chicken faces: the way it last hopped (forward when a run starts). The scene turns the picture to it.
    private(set) var facing: Move = .up

    /// After a hit by a car: which car, and where the chicken ran into it. Nil in every other state.
    private(set) var crash: Crash?

    /// How far along the level the chicken is: 0 on the start row, 1 on the finish row.
    /// It goes back down when the chicken hops back, and resets with a new run.
    var progress: Double {
        guard rows.count > 1 else { return 0 }
        return Double(playerRow) / Double(rows.count - 1)
    }

    /// Called once when the player reaches the finish. The game uses it to mark this objective as done.
    var onCompleted: (() -> Void)?

    /// Asked before every sound. The laptop says no while the minigame is not what the player is looking at
    /// (see LaptopViewModel), because the world keeps running behind the other tab and a hit there must not be heard.
    var isAudible: () -> Bool = { true }

    private let sound: SoundService

    private var restartCountdown: TimeInterval = 0

    init(sound: SoundService = .shared) {
        self.sound = sound
        startNewRun()
    }

    // MARK: - Input

    func move(_ direction: Move) {
        if case .ended = state { return }

        var row = playerRow
        var x = playerX
        switch direction {
        case .up:    row += 1
        case .down:  row -= 1
        case .left:  x -= 1
        case .right: x += 1
        }
        guard rows.indices.contains(row) else { return }

        let columns = CGFloat(MinigameConfig.columns)
        x = min(max(x, 0.5), columns - 0.5)
        if row == playerRow && x == playerX { return }     // pushed against the edge, nothing happened

        // On land the chicken snaps to the grid. Only the river lets it sit between cells.
        if rows[row].type != .river {
            x = (x - 0.5).rounded() + 0.5
        }

        playerRow = row
        playerX = x
        if state == .ready { state = .playing }            // the first move starts the run

        facing = direction                                 // it faces the way it went
        // The hop first, then whatever it lands on (a hit, a splash). Its pitch goes with the way the chicken now faces.
        playSound(.hop, pitch: SoundConfig.hopPitch(facing: facing))
        resolveHazards(after: direction)
        if state == .playing && playerRow == rows.count - 1 { finish(.won) }
    }

    // MARK: - Game loop (the scene calls this every frame)

    func update(deltaTime: TimeInterval) {
        let dt = min(deltaTime, 0.05)      // a long frame must not teleport cars through the chicken

        switch state {
        case .ended(let outcome):
            // The world does not stop for the end of a run, only the chicken does: the cars and logs keep going
            // (and the scene plays the outcome on top of them). Dying restarts the run after a short while.
            // A win is final: the game has marked this objective as done, so the run stays as it is.
            advanceWorld(by: dt)
            guard outcome != .won else { return }
            restartCountdown -= dt
            if restartCountdown <= 0 { startNewRun() }

        case .ready:
            advanceWorld(by: dt)

        case .playing:
            // A log carries the chicken. Decide that before the world moves.
            let lane = rows[playerRow]
            let ridingLog = lane.type == .river && lane.obstacle(under: playerX) != nil

            advanceWorld(by: dt)
            if ridingLog { playerX += lane.direction.sign * lane.speed * CGFloat(dt) }
            resolveHazards(after: nil)
        }
    }

    // MARK: - Helpers

    private func advanceWorld(by dt: TimeInterval) {
        for i in rows.indices { rows[i].advance(by: dt) }
    }

    /// `move` is the hop the chicken just made, or nil when the world moved into it (a car drove into the chicken).
    private func resolveHazards(after move: Move?) {
        guard state == .playing else { return }
        let lane = rows[playerRow]

        switch lane.type {
        case .safe:
            break
        case .road:
            if let car = lane.hitObstacle(at: playerX, radius: MinigameConfig.playerRadius) {
                finish(.hitByCar, crash: makeCrash(into: car, in: lane, after: move))
            }
        case .river:
            let onLog = lane.obstacle(under: playerX) != nil
            let onScreen = playerX >= 0 && playerX <= CGFloat(MinigameConfig.columns)
            if !onLog || !onScreen { finish(.drowned) }
        }
    }

    /// Where on the car the chicken ran into it. The scene draws the chicken flattened against that spot.
    private func makeCrash(into car: Obstacle, in lane: Row, after move: Move?) -> Crash {
        let relative = playerX - car.x                  // where the chicken is along the car (negative = left of its center)
        let half = car.width / 2

        // The end of the car it ran into (+1 = the right end, -1 = the left end), or nil when it ran into the car's side.
        let end: CGFloat?
        switch move {
        case .left?:        end = 1                     // hopped left into the car: it came from the right
        case .right?:       end = -1
        case .up?, .down?:  end = abs(relative) > half ? (relative > 0 ? 1 : -1) : nil    // landed just past the car's end
        case nil:           end = lane.direction.sign   // the car drove into it: the front of the car
        }

        if let end {
            return Crash(obstacleID: car.id, side: end == lane.direction.sign ? .front : .back, offset: 0)
        }
        // A hop up arrives at the side that faces down the screen, a hop down at the one that faces up.
        return Crash(obstacleID: car.id, side: move == .up ? .bottom : .top, offset: min(max(relative, -half), half))
    }

    private func finish(_ outcome: Outcome, crash: Crash? = nil) {
        state = .ended(outcome)
        self.crash = crash
        restartCountdown = MinigameConfig.restartDelay

        switch outcome {
        case .hitByCar: playSound(.hit)
        case .drowned:  playSound(.drown)
        case .won:      break           // the hop onto the finish row already made its sound
        }

        if outcome == .won { onCompleted?() }
    }

    /// `pitch` is in cents (100 = one semitone) and leaves the sound as it is at 0 (see SoundService.play(_:pitch:)).
    private func playSound(_ sound: Sound, pitch: Float = 0) {
        guard isAudible() else { return }
        self.sound.play(sound, pitch: pitch)
    }

    private func startNewRun() {
        rows = LevelGenerator.makeLevel()
        levelVersion += 1
        playerRow = 0
        playerX = CGFloat(MinigameConfig.columns / 2) + 0.5    // middle cell of the start row
        facing = .up                                           // every run starts facing forward
        crash = nil
        restartCountdown = 0
        state = .ready
    }
}
