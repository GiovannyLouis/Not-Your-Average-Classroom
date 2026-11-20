//
//  MinigameLayout.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation
import AppKit

/// Point sizes, timings and asset names live in the view layer. The model only knows about cells.
///
/// The art, and the size each picture is drawn at (cell = `cellSize` points, so with the default 88 and 13 columns):
///  - rows: grass, river, road_start, road, road_end, and start / end for the first and last row (which are safe spots).
///    One long picture per row, drawn at exactly one row (13 cells wide, 1 cell tall: 1144 x 88 points).
///  - the cat: mcidle_1..3, jump, mcdrown_1..3, mchit, mcwin_1..2 (and mc, used when there are no idle pictures).
///    All drawn FACING UP (forward), turned to the way the cat last hopped. They all share one scale: the one that makes
///    mcidle_1 `playerHeight` tall. So draw them on the same pixel grid and they keep their size from one picture to the next.
///  - car_1, car_2, car_3: 1.5, 1.7 and 2.2 cells long (see CarModel). The height follows the picture.
///  - log: ONE cell long (88 points). A log is this picture repeated 2, 3 or 4 times. The height follows the picture.
///  - win, hit, drown: the picture shown over the minigame when the run ends that way. Drawn at its own size,
///    only made smaller if it would take more than `outcomeMaxFraction` of the screen.
/// A picture that is not in the project yet is replaced by something plain (a color, the picture it is built on, or text).
enum MinigameLayout {
    static let cellSize: CGFloat = 88
    /// How many rows of the field the laptop screen shows at once. This sets the laptop's height too (LaptopLayout).
    static let visibleRows = 8

    static var size: CGSize {
        CGSize(width: CGFloat(MinigameConfig.columns) * cellSize,
               height: CGFloat(visibleRows) * cellSize)
    }

    // MARK: - Asset names

    static let grassAssetName = "grass"
    static let startAssetName = "start"
    static let endAssetName = "end"
    static let riverAssetName = "river"
    static let roadStartAssetName = "road_start"
    static let roadAssetName = "road"
    static let roadEndAssetName = "road_end"

    static let playerAssetName = "mc"                                    // only when there are no idle pictures
    static let idleAssetNames = ["mcidle_1", "mcidle_2", "mcidle_3"]
    static let jumpAssetName = "jump"
    static let drownAssetNames = ["mcdrown_1", "mcdrown_2", "mcdrown_3"]
    static let hitAssetName = "mchit"
    static let winAssetNames = ["mcwin_1", "mcwin_2"]

    static let logAssetName = "log"

    /// The picture row number `index` of `count` rows is drawn with. The first and last row are safe spots with their own picture.
    static func assetName(for row: Row, at index: Int, of count: Int) -> String {
        switch row.type {
        case .safe:
            if index == 0 { return startAssetName }
            if index == count - 1 { return endAssetName }
            return grassAssetName
        case .river:
            return riverAssetName
        case .road:
            switch row.roadPart {
            case .start:  return roadStartAssetName
            case .middle: return roadAssetName
            case .end:    return roadEndAssetName
            }
        }
    }

    static func assetName(for car: CarModel) -> String {
        switch car {
        case .car1: return "car_1"
        case .car2: return "car_2"
        case .car3: return "car_3"
        }
    }

    static func outcomeAssetName(for outcome: Outcome) -> String {
        switch outcome {
        case .won:      return "win"
        case .hitByCar: return "hit"
        case .drowned:  return "drown"
        }
    }

    /// Every picture the minigame looks for (the scene prints the ones the project does not have yet, in a debug build).
    static var allAssetNames: [String] {
        var names = [grassAssetName, startAssetName, endAssetName, riverAssetName,
                     roadStartAssetName, roadAssetName, roadEndAssetName,
                     jumpAssetName, hitAssetName, logAssetName]
        names += idleAssetNames
        names += drownAssetNames
        names += winAssetNames
        names += CarModel.allCases.map { assetName(for: $0) }
        names += [Outcome.won, Outcome.hitByCar, Outcome.drowned].map { outcomeAssetName(for: $0) }
        return names
    }

    // MARK: - The cat

    /// How tall mcidle_1 is drawn, in points (its width follows the picture), and so the scale of every cat picture.
    /// The pictures face up, so this is the length from tail to head when it hops forward.
    /// The hit box does not change with it (MinigameConfig.playerRadius).
    static let playerHeight: CGFloat = cellSize * 0.8

    /// Seconds each picture of an animation is shown.
    static let idleFrameDuration: TimeInterval = 0.5        // mcidle_1, 2, 3, 1, 2, 3, ...
    static let drownFrameDuration: TimeInterval = 0.2       // mcdrown_1, 2, 3 once (0.6s in all), then the cat is gone
    static let winFrameDuration: TimeInterval = 0.3         // mcwin_1, 2, 1, 2, ... for as long as the world runs

    /// How big the cat gets in the middle of a hop (1.1 = 10% bigger), going back to 1 as it lands.
    static let jumpScale: CGFloat = 1.1

    /// How long a win takes for one clockwise turn, in seconds. Smaller = spins faster.
    static let winSpinPeriod: CGFloat = 1.2

    /// How flat the cat is when a car runs into it from the side or the back: 0.2 = a fifth of its length (along the
    /// way it faces). A hit from the front does not flatten it, mchit is already flat.
    static let flattenScale: CGFloat = 0.2

    /// How many points the flattened cat overlaps the car it is stuck to. 0 = just touching.
    static let crashOverlap: CGFloat = 2

    /// How the cat is turned (counterclockwise, in radians) to face the way it last hopped. The pictures face up.
    static func facingAngle(of move: Move) -> CGFloat {
        switch move {
        case .up:    return 0
        case .left:  return .pi / 2
        case .down:  return .pi
        case .right: return -.pi / 2
        }
    }

    // MARK: - Other sizes

    /// Which way the cars in the pictures car_1..3 are drawn to drive. A row that drives the other way gets them mirrored.
    static let carArtFaces: LaneDirection = .left

    /// Neighbouring pictures (rows, and the tiles of a log) overlap by this many points, so that no hairline of the
    /// background shows between them while the camera sits between two pixels. Set both to 0 to take it away.
    static let rowOverlap: CGFloat = 1
    static let tileOverlap: CGFloat = 1

    /// How long the progress bar takes to fade out once the run is won, in seconds.
    static let progressFadeDuration: TimeInterval = 1

    /// The most of the screen's width or height a win / hit / drown picture may take (0.8 = 80%).
    static let outcomeMaxFraction: CGFloat = 0.8

    /// The size to show the win / hit / drown picture at, or nil when the project does not have it yet.
    static func outcomeImageSize(for outcome: Outcome) -> CGSize? {
        guard let natural = NSImage(named: NSImage.Name(outcomeAssetName(for: outcome)))?.size,
              natural.width > 0, natural.height > 0 else { return nil }
        let fit = min(1, size.width * outcomeMaxFraction / natural.width, size.height * outcomeMaxFraction / natural.height)
        return CGSize(width: natural.width * fit, height: natural.height * fit)
    }
}
