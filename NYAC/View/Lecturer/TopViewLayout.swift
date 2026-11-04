//
//  TopViewLayout.swift
//  NYAC
//
//  Created by Vrz on 04/11/26.
//

import Foundation
import CoreGraphics

/// Where everything sits in the top view. The numbers are measured from the sketch (738 x 900 px, y pointing down)
/// and converted so the middle of the drawing is (0, 0) and y points up, like SpriteKit.
/// They are in "sketch units": TopViewNode scales the whole drawing to whatever size the scene gives it.
enum TopViewLayout {

    /// The area the drawing occupies, labels included.
    static let size = CGSize(width: 660, height: 790)
    static let cornerRadius: CGFloat = 28

    // MARK: - Dot sizes

    static let spotRadius: CGFloat = 20
    static let lecturerRadius: CGFloat = 17        // a little smaller than a spot, so the spot still shows under the lecturer
    static let playerRadius: CGFloat = 21

    // MARK: - Furniture

    static let whiteboardCenter = sketch(361, 155)
    static let whiteboardSize = CGSize(width: 397, height: 44)
    static let whiteboardLabel = sketch(355, 92)

    static let deskCenter = sketch(349, 710)
    static let deskSize = CGSize(width: 172, height: 76)
    static let deskLaptopCenter = sketch(362, 689)
    static let deskLaptopSize = CGSize(width: 80, height: 14)
    static let playerPosition = sketch(355, 722)
    static let playerLabel = sketch(355, 645)

    // MARK: - The walkway
    // A rectangle the lecturer walks around. B and C are its top corners; A and D sit on its left and right
    // sides, level with the player. The walk between A and D goes around the bottom corners, behind the player.

    private static let left: CGFloat = 122
    private static let right: CGFloat = 596
    private static let top: CGFloat = 221
    private static let spotY: CGFloat = 709
    private static let bottom: CGFloat = 826

    /// The four corners of the dashed path, in order.
    static let walkway: [CGPoint] = [
        sketch(left, top), sketch(right, top), sketch(right, bottom), sketch(left, bottom)
    ]

    static func position(of spot: LecturerSpot) -> CGPoint {
        switch spot {
        case .a: return sketch(left, spotY)
        case .b: return sketch(left, top)
        case .c: return sketch(right, top)
        case .d: return sketch(right, spotY)
        }
    }

    /// Where a spot's letter goes, relative to the spot: away from the middle of the room.
    static func labelOffset(for spot: LecturerSpot) -> CGPoint {
        switch spot {
        case .a: return CGPoint(x: -38, y: -34)
        case .b: return CGPoint(x: -38, y: 34)
        case .c: return CGPoint(x: 38, y: 34)
        case .d: return CGPoint(x: 38, y: -34)
        }
    }

    // MARK: - Routes

    /// The points the lecturer walks through to get from one spot to a neighbor.
    static func route(from start: LecturerSpot, to end: LecturerSpot) -> [CGPoint] {
        let backLeft = sketch(left, bottom)
        let backRight = sketch(right, bottom)

        switch (start, end) {
        case (.a, .d): return [position(of: .a), backLeft, backRight, position(of: .d)]
        case (.d, .a): return [position(of: .d), backRight, backLeft, position(of: .a)]
        default:       return [position(of: start), position(of: end)]
        }
    }

    /// The point `t` of the way (0...1) along a route, measured by distance. Whatever the route's length,
    /// the walk takes the same time, so a long route is just walked faster.
    static func point(along route: [CGPoint], at t: CGFloat) -> CGPoint {
        guard route.count > 1 else { return route.first ?? .zero }

        let lengths = (1..<route.count).map { index in
            hypot(route[index].x - route[index - 1].x, route[index].y - route[index - 1].y)
        }
        var remaining = min(max(t, 0), 1) * lengths.reduce(0, +)

        for (index, length) in lengths.enumerated() {
            if remaining <= length || index == lengths.count - 1 {
                let fraction = length > 0 ? min(remaining / length, 1) : 0
                let from = route[index]
                let to = route[index + 1]
                return CGPoint(x: from.x + (to.x - from.x) * fraction,
                               y: from.y + (to.y - from.y) * fraction)
            }
            remaining -= length
        }
        return route[route.count - 1]
    }

    // MARK: - Sketch coordinates

    /// Sketch pixel -> centered, y-up drawing space. (370, 455) is the middle of the drawing area.
    private static func sketch(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x - 370, y: 455 - y)
    }
}
