//
//  MinigameLayout.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation

/// Point sizes and asset names live in the view layer. The model only knows about cells.
///
/// The art, and the size each picture is drawn at (cell = `cellSize` points, so with the default 88 and 13 columns):
///  - rows: grass, river, road_start, road, road_end. One long picture per row, drawn at exactly one row
///    (13 cells wide, 1 cell tall: 1144 x 88 points, or 2288 x 176 pixels for a @2x picture).
///  - mc: the chicken, drawn FACING UP (forward). It turns to face the way it last hopped. It is `playerHeight` tall.
///  - car_1, car_2, car_3: 1.5, 1.7 and 2.2 cells long (see CarModel). The height follows the picture.
///  - log: ONE cell long (88 points). A log is this picture repeated 2, 3 or 4 times. The height follows the picture.
/// A picture that is not in the project yet is replaced by the plain colored shape the game started with.
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
    static let riverAssetName = "river"
    static let roadStartAssetName = "road_start"
    static let roadAssetName = "road"
    static let roadEndAssetName = "road_end"

    static let playerAssetName = "mc"
    static let logAssetName = "log"

    /// The picture a row is drawn with.
    static func assetName(for row: Row) -> String {
        switch row.type {
        case .safe:  return grassAssetName
        case .river: return riverAssetName
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

    /// Every picture the minigame looks for (the scene prints the ones the project does not have yet, in a debug build).
    static var allAssetNames: [String] {
        [grassAssetName, riverAssetName, roadStartAssetName, roadAssetName, roadEndAssetName,
         playerAssetName, logAssetName] + CarModel.allCases.map { assetName(for: $0) }
    }

    // MARK: - Sizes

    /// How tall the chicken's picture is, in points (its width follows the picture). It is drawn facing up, so this is
    /// the length it has from tail to head when it hops forward. The hit box does not change with it (MinigameConfig.playerRadius).
    static let playerHeight: CGFloat = cellSize * 0.8

    /// Which way the cars in the pictures car_1..3 are drawn to drive. A row that drives the other way gets them mirrored.
    static let carArtFaces: LaneDirection = .left

    /// Neighbouring pictures (rows, and the tiles of a log) overlap by this many points, so that no hairline of the
    /// background shows between them while the camera sits between two pixels. Set both to 0 to take it away.
    static let rowOverlap: CGFloat = 1
    static let tileOverlap: CGFloat = 1

    // MARK: - Facing

    /// How far the chicken's picture is turned (counterclockwise, in radians) to face the way it last hopped.
    /// The picture itself faces up.
    static func facingAngle(of move: Move) -> CGFloat {
        switch move {
        case .up:    return 0
        case .left:  return .pi / 2
        case .down:  return .pi
        case .right: return -.pi / 2
        }
    }
}
