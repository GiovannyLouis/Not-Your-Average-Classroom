//
//  ClassroomLayout.swift
//  NYAC
//
//  Created by Vrz on 11/11/26.
//


import Foundation
import CoreGraphics

/// Where everything sits in the classroom scene, how fast each layer moves, and what is drawn in front of what.
///
/// Positions are measured from the greybox sketch (1946 x 1272 px, y pointing down) and converted so the middle of the
/// sketch is (0, 0) and y points up, like SpriteKit. They are in "design units": ClassroomNode scales the whole room
/// to whatever size the scene has.
///
/// Speed and draw order are two separate things, and are kept apart on purpose:
///  - speed is the multiplier of a parallax layer, shared by every item in that layer (`multiplier(of:)`)
///  - draw order is the z position of each item (`zPosition(of:)`), so the middle desk of a row can be in front
///    of the side desks and still move at the same speed as them
enum ClassroomLayout {

    // MARK: - Design space

    /// The size of the sketch. The room is scaled so that this always covers the whole screen.
    static let designSize = CGSize(width: 1946, height: 1272)

    /// How many points one design unit is on a scene of the given size. It fills the scene (nothing is left empty),
    /// and crops a little off the sides or the top and bottom when the screen is not shaped like the sketch.
    static func scale(fitting sceneSize: CGSize) -> CGFloat {
        max(sceneSize.width / designSize.width, sceneSize.height / designSize.height)
    }

    // MARK: - Speed (parallax multipliers)

    // Fractions of the scene's maxShift, from the closest layer to the furthest. The laptop sits above all of these
    // (0.25 in focus, 0.20 in peek, set in ParallaxScene), so each layer has to stay below that.
    // The bigger the gap between two layers, the stronger the sense of depth between them.

    static func multiplier(of layer: ParallaxLayer) -> CGFloat {
        switch layer {
        case .secondRowDesks: return 0.2
        case .firstRowDesks:  return 0.1
        case .windowAndDoor:  return 0.07
        case .whiteboard:     return 0.03
        }
    }

    // MARK: - Draw order (z positions)

    /// The z gap between two layers. Big on purpose, so a layer never ends up level with its neighbour.
    private static let layerGap: CGFloat = 10

    /// How much further forward the middle desk of a row is than the desks at its sides.
    private static let middleDeskLift: CGFloat = 2

    /// Higher z = drawn in front. From the back: whiteboard 0, window and door 10, first row 20 (F 22), second row 30 (C 32).
    static func zPosition(of item: ClassroomItem) -> CGFloat {
        let base: CGFloat
        switch item.layer {
        case .whiteboard:     base = 0
        case .windowAndDoor:  base = layerGap
        case .firstRowDesks:  base = layerGap * 2
        case .secondRowDesks: base = layerGap * 3
        }
        return base + (item.isMiddleOfRow ? middleDeskLift : 0)
    }

    /// The top view of the classroom (with the lecturer) hangs in front of the whiteboard. Its own layers go up
    /// to 5, so this keeps all of it below the window and the door.
    static var topViewZPosition: CGFloat {
        zPosition(of: .whiteboard) + 1
    }

    // MARK: - Positions

    /// Where the item is on the sketch.
    static func frame(of item: ClassroomItem) -> CGRect {
        switch item {
        case .secondRowLeft:   return rect(0, 825, 598, 1272)
        case .secondRowMiddle: return rect(658, 825, 1288, 1272)
        case .secondRowRight:  return rect(1348, 825, 1946, 1272)
        case .firstRowLeft:    return rect(248, 720, 698, 1025)
        case .firstRowMiddle:  return rect(748, 720, 1198, 1025)
        case .firstRowRight:   return rect(1248, 720, 1698, 1025)
        case .window:          return rect(44, 330, 318, 750)
        case .door:            return rect(1735, 365, 1946, 860)
        case .whiteboard:      return rect(673, 355, 1273, 665)
        }
    }

    /// How far an item that the sketch cuts off at the screen edge keeps going past it.
    /// The layers slide sideways when the head moves, and without this the edge of the desk would slide into view.
    static let edgeBleed: CGFloat = 400

    /// What actually gets drawn: the sketch's frame, plus the bleed for items that touch the left or right edge.
    static func drawnFrame(of item: ClassroomItem) -> CGRect {
        var result = frame(of: item)
        let halfWidth = designSize.width / 2

        if result.minX <= -halfWidth {
            result.origin.x -= edgeBleed
            result.size.width += edgeBleed
        }
        if result.maxX >= halfWidth {
            result.size.width += edgeBleed
        }
        return result
    }

    // MARK: - Whiteboard

    /// The empty border kept between the whiteboard's edge and the top view inside it.
    static let whiteboardInset: CGFloat = 16

    // MARK: - Letters (greybox only)

    /// Prints the sketch's letter on every item. Turn it off once the real art replaces the boxes.
    static let showsLetters = true

    /// Where the letter goes. The first row desks are mostly hidden behind the second row, so theirs sits
    /// on the strip that stays visible, like in the sketch.
    static func letterPosition(of item: ClassroomItem) -> CGPoint {
        let box = frame(of: item)
        switch item.layer {
        case .firstRowDesks: return CGPoint(x: box.midX, y: box.maxY - 38)
        default:             return CGPoint(x: box.midX, y: box.midY)
        }
    }

    static func letterSize(of item: ClassroomItem) -> CGFloat {
        item.layer == .firstRowDesks ? 56 : 90
    }

    // MARK: - Sketch coordinates

    /// Sketch pixels (left, top, right, bottom; y down) -> centered, y-up design space.
    private static func rect(_ left: CGFloat, _ top: CGFloat, _ right: CGFloat, _ bottom: CGFloat) -> CGRect {
        CGRect(x: left - designSize.width / 2,
               y: designSize.height / 2 - bottom,
               width: right - left,
               height: bottom - top)
    }
}
