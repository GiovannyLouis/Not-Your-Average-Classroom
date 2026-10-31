//
//  MinigameViewModel.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation
import Combine

final class MinigameViewModel: ObservableObject {

    // Observed by SwiftUI (result label).
    @Published private(set) var state: MinigameState = .ready

    // Read by the scene every frame. Deliberately not @Published: they change 60x a second.
    private(set) var rows: [Row] = []
    private(set) var playerRow = 0
    private(set) var playerX: CGFloat = 0          // in cells, may sit between cells on a log
    private(set) var levelVersion = 0              // bumps whenever a new level is generated

    /// Called once when the player reaches the finish. The laptop uses it to mark this tab as done.
    var onCompleted: (() -> Void)?

    private var restartCountdown: TimeInterval = 0

    init() {
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

        resolveHazards()
        if state == .playing && playerRow == rows.count - 1 { finish(.won) }
    }

    // MARK: - Game loop (the scene calls this every frame)

    func update(deltaTime: TimeInterval) {
        let dt = min(deltaTime, 0.05)      // a long frame must not teleport cars through the chicken

        switch state {
        case .ended(let outcome):
            // Dying restarts the run after a short pause. A win is final: the laptop has marked
            // this tab as done, so the run stays exactly as it is.
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
            resolveHazards()
        }
    }

    // MARK: - Helpers

    private func advanceWorld(by dt: TimeInterval) {
        for i in rows.indices { rows[i].advance(by: dt) }
    }

    private func resolveHazards() {
        guard state == .playing else { return }
        let lane = rows[playerRow]

        switch lane.type {
        case .safe:
            break
        case .road:
            if lane.isHit(at: playerX, radius: MinigameConfig.playerRadius) { finish(.hitByCar) }
        case .river:
            let onLog = lane.obstacle(under: playerX) != nil
            let onScreen = playerX >= 0 && playerX <= CGFloat(MinigameConfig.columns)
            if !onLog || !onScreen { finish(.drowned) }
        }
    }

    private func finish(_ outcome: Outcome) {
        state = .ended(outcome)
        restartCountdown = MinigameConfig.restartDelay
        if outcome == .won { onCompleted?() }
    }

    private func startNewRun() {
        rows = LevelGenerator.makeLevel()
        levelVersion += 1
        playerRow = 0
        playerX = CGFloat(MinigameConfig.columns / 2) + 0.5    // middle cell of the start row
        restartCountdown = 0
        state = .ready
    }
}

