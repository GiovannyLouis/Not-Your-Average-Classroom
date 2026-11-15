//
//  LecturerWalkLayout.swift
//  NYAC
//
//  Created by Vrz on 15/11/26.
//

import Foundation
import CoreGraphics

/// Where the lecturer is drawn in the classroom while he stands at B or C and while he walks, and how every walk looks.
/// This is the one place to tune the walk animations. The numbers were measured from the mock screenshots.
///
/// Positions are in the classroom's design units (ClassroomLayout): the middle of the screen is (0, 0), y points up.
/// The sprite is placed by its feet (the middle of its bottom edge), and `scale` is 1 when he stands at B or C.
///
/// Which walks are drawn (the lecturer's spots are the letters A B C D of the top view, not the desks of the greybox):
///   B <-> C       across the front of the whiteboard, through the gaps of the first row desks (C to B is the mirror image)
///   B  -> A       toward the player on the left: faster, bigger and further forward the closer he gets, until he is off the screen
///   C  -> D       the same, mirrored, on the right
///   A  -> B       B to A played backwards, walking away, with the sprite that faces away (lecturer_back)
///   D  -> C       C to D played backwards, mirrored
///   A <-> D       he is behind the player, so nothing is drawn (for now)
enum LecturerWalkLayout {

    // MARK: - Size

    /// The sprite's height when he stands at B or C, in design units.
    static let height: CGFloat = 510

    /// The sprite's width for its height (lecturer.png is 274 x 683). The real art keeps its own proportions;
    /// this sizes the greybox, and keeps the end point of a walk toward the player off the screen.
    static let aspect: CGFloat = 0.4

    // MARK: - Standing at B and C

    /// How far from the middle of the room his feet are when he stands at B (to the left) or at C (to the right):
    /// in the gap between the first row desks.
    static let standX: CGFloat = 225

    /// How high his feet are when he stands at B or C. They are hidden behind the first row desks.
    static let standFeetY: CGFloat = -406

    /// Draw order while he stands or walks across: in front of the whiteboard and the window and door (0 and 10),
    /// behind the first row desks (20, and 22 for the middle one).
    static let standZ: CGFloat = (ClassroomLayout.zPosition(of: .window) + ClassroomLayout.zPosition(of: .firstRowLeft)) / 2

    // MARK: - Walking toward and away from the player (B <-> A, C <-> D)

    /// How big he is when he reaches the player's side (A or D), where he is off the screen. 1 = as big as at B.
    static let arrivalScale: CGFloat = 8

    // Draw order on the way. It follows his size, so it does not change when the speed of the walk does: he stays at
    // `standZ` (behind the first row desks) while he is at his smallest, is just in front of the first row desks (20, and
    // 22 for the middle one) once he is `frontOfFirstRowAtScale` big, just in front of the second row desks (30, and 32 for
    // the middle one) at `frontOfSecondRowAtScale`, and `arrivalZ` at the end. In between, his z is a straight line.
    // Keep them in this order: 1 < frontOfFirstRowAtScale < frontOfSecondRowAtScale < arrivalScale.

    static let frontOfFirstRowAtScale: CGFloat = 1.5
    static let frontOfSecondRowAtScale: CGFloat = 2.2
    static let arrivalZ: CGFloat = ClassroomLayout.zPosition(of: .secondRowMiddle) + 8

    /// How much lower his feet are for every extra 1.0 of scale: closer to the player = lower on the screen.
    /// Together with `arrivalScale` this is where his feet end up.
    static let feetDropPerScale: CGFloat = 263

    /// How far past the screen edge he ends up, so he is surely out of sight when the walk is over.
    static let offscreenMargin: CGFloat = 150

    /// How far out to the side his feet are at the end of the walk (the distance from the middle of the room).
    /// Worked out from `arrivalScale`, so a bigger sprite still ends up fully off the screen. Write a number here to place it by hand.
    static var arrivalX: CGFloat {
        ClassroomLayout.designSize.width / 2 + height * aspect * arrivalScale / 2 + offscreenMargin
    }

    /// How high his feet are at the end of the walk.
    static var arrivalFeetY: CGFloat {
        standFeetY - feetDropPerScale * (arrivalScale - 1)
    }

    /// How "progressive" the walk toward the player is. The position and the size follow the same
    /// curve: progress ^ acceleration. 1 = constant speed. The bigger it is, the more he lingers near B at first and
    /// the harder he rushes at the end. (Walking away plays the same curve backwards.)
    static let acceleration: CGFloat = 2.8

    // MARK: - Parallax speed

    // How fast he follows the head movement, as a fraction of the scene's maxShift (like ClassroomLayout.multiplier).
    // Standing, he is somewhere between the whiteboard and the first row desks. The closer he comes, the closer
    // his speed goes to the second row desks'. Keep it under the laptop's 0.3.

    static let standMultiplier: CGFloat = (ClassroomLayout.multiplier(of: .whiteboard) + ClassroomLayout.multiplier(of: .firstRowDesks)) / 2
    static let arrivalMultiplier: CGFloat = 0.25

    /// His parallax speed at a point of the walk toward the player. `closeness` is 0 at B or C and 1 at A or D.
    static func multiplier(closeness: CGFloat) -> CGFloat {
        standMultiplier + (arrivalMultiplier - standMultiplier) * closeness
    }

    // MARK: - Footsteps

    // The speed of the steps is LecturerConfig.stepsPerSecond (the footstep sound will use it too).

    /// How high each step lifts him, in design units at scale 1. It grows with his size, so a step is bigger when he is close.
    static let stepHeight: CGFloat = 16

    /// A walk starts and ends this many seconds calmly, so he never jumps when he starts or stops.
    static let stepFadeTime: CGFloat = 0.3

    /// How far up the footsteps lift him, `progress` of the way through a walk of `LecturerConfig.moveDuration`.
    /// One bounce per step, always on the ground at the start and the end of the walk.
    static func stepLift(progress: CGFloat, scale: CGFloat) -> CGFloat {
        let total = CGFloat(LecturerConfig.moveDuration)
        let seconds = progress * total

        let edge = max(min(seconds, total - seconds), 0)
        let fade = min(edge / stepFadeTime, 1)
        let smooth = fade * fade * (3 - 2 * fade)

        let wave = abs(sin(CGFloat.pi * seconds * CGFloat(LecturerConfig.stepsPerSecond)))
        return stepHeight * scale * wave * smooth
    }

    // MARK: - The pose

    enum Side {
        case left, right
    }

    /// Which of the two sprites is drawn: the one facing the player (lecturer) or the one facing away (lecturer_back).
    enum Facing {
        case front, back
    }

    /// Everything the node needs to draw the lecturer at one moment.
    struct Pose {
        /// The middle of the sprite's bottom edge, without the step.
        var feet: CGPoint
        /// How much the footsteps lift him on top of `feet`.
        var lift: CGFloat
        var scale: CGFloat
        var z: CGFloat
        var facing: Facing
        /// Whether the sprite is flipped left to right.
        var isMirrored: Bool
        /// 0 while he is at B, C or walking across; 0...1 on the way between B or C and the player's side.
        var closeness: CGFloat
    }

    /// Where the lecturer is and how he looks. `progress` is how far through the walk he is (0...1).
    /// Nil when he can't be seen: at A or D, or on the way between them.
    static func pose(for state: LecturerState, progress: CGFloat) -> Pose? {
        switch state {
        case .staying(let spot):
            guard spot.isSafe else { return nil }
            return standing(on: side(of: spot))

        case .moving(let from, let to):
            let t = min(max(progress, 0), 1)
            switch (from.isSafe, to.isSafe) {
            case (true, true):
                return crossing(from: side(of: from), to: side(of: to), progress: t)
            case (true, false):
                return toward(side: side(of: from), along: pow(t, acceleration), progress: t)
            case (false, true):
                return away(side: side(of: to), along: pow(1 - t, acceleration), progress: t)
            case (false, false):
                return nil
            }
        }
    }

    /// B and A are on the left, C and D on the right.
    private static func side(of spot: LecturerSpot) -> Side {
        switch spot {
        case .a, .b: return .left
        case .c, .d: return .right
        }
    }

    private static func sign(of side: Side) -> CGFloat {
        side == .left ? -1 : 1
    }

    private static func standing(on side: Side) -> Pose {
        Pose(feet: CGPoint(x: sign(of: side) * standX, y: standFeetY), lift: 0, scale: 1, z: standZ,
             facing: .front, isMirrored: false, closeness: 0)
    }

    /// B to C or C to B: along the line between the two spots, at a steady speed. The mirror image just goes the other way.
    private static func crossing(from start: Side, to end: Side, progress t: CGFloat) -> Pose {
        let startX = sign(of: start) * standX
        let endX = sign(of: end) * standX

        return Pose(feet: CGPoint(x: startX + (endX - startX) * t, y: standFeetY),
                    lift: stepLift(progress: t, scale: 1), scale: 1, z: standZ,
                    facing: .front, isMirrored: start == .right, closeness: 0)
    }

    /// B to A or C to D: `f` is how far he is along the way (0 at the spot, 1 at the player's side).
    private static func toward(side: Side, along f: CGFloat, progress t: CGFloat) -> Pose {
        placed(side: side, along: f, facing: .front, isMirrored: side == .left, progress: t)
    }

    /// A to B or D to C: the same way, walked backwards, seen from behind.
    private static func away(side: Side, along f: CGFloat, progress t: CGFloat) -> Pose {
        placed(side: side, along: f, facing: .back, isMirrored: side == .right, progress: t)
    }

    private static func placed(side: Side, along f: CGFloat, facing: Facing, isMirrored: Bool, progress t: CGFloat) -> Pose {
        let scale = 1 + (arrivalScale - 1) * f

        return Pose(feet: CGPoint(x: sign(of: side) * (standX + (arrivalX - standX) * f),
                                  y: standFeetY + (arrivalFeetY - standFeetY) * f),
                    lift: stepLift(progress: t, scale: scale),
                    scale: scale,
                    z: z(atScale: scale),
                    facing: facing,
                    isMirrored: isMirrored,
                    closeness: f)
    }

    /// His draw order at a size: a straight line between the stops (size, z) described next to `frontOfFirstRowAtScale`.
    private static func z(atScale scale: CGFloat) -> CGFloat {
        let stops: [(scale: CGFloat, z: CGFloat)] = [
            (1, standZ),
            (frontOfFirstRowAtScale, ClassroomLayout.zPosition(of: .firstRowMiddle) + 1),
            (frontOfSecondRowAtScale, ClassroomLayout.zPosition(of: .secondRowMiddle) + 1),
            (arrivalScale, arrivalZ)
        ]

        for index in 1..<stops.count {
            let from = stops[index - 1]
            let to = stops[index]
            guard scale < to.scale, to.scale > from.scale else { continue }

            let t = max((scale - from.scale) / (to.scale - from.scale), 0)
            return from.z + (to.z - from.z) * t
        }
        return arrivalZ
    }
}
