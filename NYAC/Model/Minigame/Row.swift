//
//  Row.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation

struct Row {
    let type: RowType
    let direction: LaneDirection
    let speed: CGFloat                         // cells per second
    let interval: TimeInterval                 // seconds between spawns
    let obstacleWidth: CGFloat                 // car / log length in cells
    var obstacles: [Obstacle] = []
    var spawnTimer: TimeInterval = 0

    static var safe: Row {
        Row(type: .safe, direction: .right, speed: 0, interval: 0, obstacleWidth: 0)
    }
}

extension Row {
    /// Moves every obstacle and spawns a new one whenever `interval` has passed.
    mutating func advance(by dt: TimeInterval) {
        guard type != .safe else { return }

        // Local copies, so the closure below doesn't capture `self` while it is being mutated.
        let direction = self.direction
        let columns = CGFloat(MinigameConfig.columns)
        let step = direction.sign * speed * CGFloat(dt)

        for i in obstacles.indices { obstacles[i].x += step }

        // Drop obstacles that have fully left the field on the far side.
        obstacles.removeAll { obstacle in
            let halfWidth = obstacle.width / 2
            return direction == .right ? obstacle.x - halfWidth > columns
                                       : obstacle.x + halfWidth < 0
        }

        spawnTimer += dt
        if spawnTimer >= interval {
            spawnTimer -= interval
            // Spawn just outside the entry edge. The leftover time is how long the
            // new obstacle has already been travelling, which keeps spacing exact.
            let entry = direction == .right ? -obstacleWidth / 2 : columns + obstacleWidth / 2
            let travelled = direction.sign * speed * CGFloat(spawnTimer)
            obstacles.append(Obstacle(x: entry + travelled, width: obstacleWidth))
        }
    }

    /// The obstacle whose body covers `x` (for logs: the chicken has to stand on one).
    func obstacle(under x: CGFloat) -> Obstacle? {
        obstacles.first { abs($0.x - x) <= $0.width / 2 }
    }

    /// True when a car overlaps a chicken of the given radius standing at `x`.
    func isHit(at x: CGFloat, radius: CGFloat) -> Bool {
        obstacles.contains { abs($0.x - x) < $0.width / 2 + radius }
    }
}
