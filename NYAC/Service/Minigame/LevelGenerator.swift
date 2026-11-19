//
//  LevelGenerator.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation

/// Builds one run's worth of rows: safe start + 20 grouped rows + safe end.
enum LevelGenerator {

    // Tuning knobs. Speeds are cells per second, gaps are cells between neighbours.
    // A road row picks one of the three cars (CarModel, each with its own length) for all of its cars.
    private static let carSpeed: ClosedRange<CGFloat> = 1.5...4.0
    private static let carGap: ClosedRange<CGFloat> = 3.0...6.0

    // A log is the 1-cell log picture repeated `logTiles` times, so its length is a whole number of cells.
    private static let logSpeed: ClosedRange<CGFloat> = 0.8...2.0
    private static let logTiles: ClosedRange<Int> = 2...4
    private static let logGap: ClosedRange<CGFloat> = 1.2...2.5

    static func makeLevel() -> [Row] {
        var rows: [Row] = [.safe]
        for group in makeGroups() {
            for index in 0..<group.count {
                // Only a road looks different from one row to the next: its first row has the sidewalk below, its last above.
                rows.append(makeRow(type: group.type, roadPart: RoadPart.of(index: index, count: group.count)))
            }
        }
        rows.append(.safe)
        return rows
    }

    // MARK: - Grouping

    private struct RowGroup {
        let type: RowType
        let count: Int
    }

    private static func sizeRange(for type: RowType) -> ClosedRange<Int> {
        switch type {
        case .road:  return 2...5
        case .river: return 1...3
        case .safe:  return 1...2
        }
    }

    /// Random groups that add up to exactly `generatedRowCount` rows.
    private static func makeGroups() -> [RowGroup] {
        var groups: [RowGroup] = []
        var remaining = MinigameConfig.generatedRowCount
        var previous = RowType.safe            // the fixed start row counts as the group before the first

        while remaining > 0 {
            // The same type never repeats back to back (it would just be one oversized group),
            // and the group's minimum size has to still fit. A river or safe group needs only
            // one row, so this can never run out of options.
            let options = [RowType.road, .river, .safe].filter {
                $0 != previous && sizeRange(for: $0).lowerBound <= remaining
            }
            let type = options.randomElement() ?? .river
            let range = sizeRange(for: type)
            let count = Int.random(in: range.lowerBound...min(range.upperBound, remaining))

            groups.append(RowGroup(type: type, count: count))
            remaining -= count
            previous = type
        }
        return groups
    }

    // MARK: - Rows

    private static func makeRow(type: RowType, roadPart: RoadPart) -> Row {
        let direction: LaneDirection = Bool.random() ? .left : .right

        switch type {
        case .safe:
            return .safe
        case .road:
            // The row's cars are all this one car, so they are all the same length.
            let car = CarModel.allCases.randomElement() ?? .car1
            return makeLane(type: .road, direction: direction,
                            speedRange: carSpeed, width: car.width, gapRange: carGap,
                            roadPart: roadPart, car: car)
        case .river:
            let width = CGFloat(Int.random(in: logTiles))
            return makeLane(type: .river, direction: direction,
                            speedRange: logSpeed, width: width, gapRange: logGap,
                            roadPart: .middle, car: nil)
        }
    }

    private static func makeLane(type: RowType,
                                 direction: LaneDirection,
                                 speedRange: ClosedRange<CGFloat>,
                                 width: CGFloat,
                                 gapRange: ClosedRange<CGFloat>,
                                 roadPart: RoadPart,
                                 car: CarModel?) -> Row {
        let speed = CGFloat.random(in: speedRange)
        let gap = CGFloat.random(in: gapRange)

        // Time between spawns that leaves `gap` cells between neighbouring obstacles.
        let interval = TimeInterval((width + gap) / speed)

        var row = Row(type: type, direction: direction, speed: speed,
                      interval: interval, obstacleWidth: width, roadPart: roadPart, car: car)
        warmUp(&row)
        return row
    }

    /// Runs a lane forward so cars and logs are already on screen when the run starts.
    private static func warmUp(_ row: inout Row) {
        row.spawnTimer = TimeInterval.random(in: 0..<row.interval)     // keeps lanes out of sync

        let crossTime = TimeInterval((CGFloat(MinigameConfig.columns) + row.obstacleWidth) / row.speed)
        let duration = crossTime + row.interval
        let step: TimeInterval = 1.0 / 30.0

        var elapsed: TimeInterval = 0
        while elapsed < duration {
            row.advance(by: step)
            elapsed += step
        }
    }
}
