//
//  ParallaxScene.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import SpriteKit

/// The parallax effect lives here. The scene has two poses and eases between them:
///  - focus: the laptop sits in front, tiny movement
///  - peek:  the laptop drops to the bottom of the screen showing only its top edge
/// In both poses, each layer moves opposite to your head, scaled by its own multiplier.
///
/// SpriteKit draws the classroom (ClassroomNode): the desks, the window, the door and the whiteboard, each parallax layer
/// with its own multiplier (see ClassroomLayout). The top view of the classroom, with the lecturer in it, hangs inside the whiteboard.
/// The nearest layer is the laptop, which is a SwiftUI view, so the scene just works out where that view
/// belongs (`laptopOffset`) and the SwiftUI side follows it every frame.
final class ParallaxScene: SKScene {

    /// Size of the near layer (the laptop). The scene needs it to know where the laptop's top edge sits in peek mode.
    var laptopSize: CGSize = LaptopLayout.size

    /// Where the laptop's center is relative to the middle of the screen, in points.
    /// SpriteKit axes: +x = right, +y = UP. Updated every frame in `update`.
    private(set) var laptopOffset: CGPoint = .zero

    // MARK: - Tuning

    /// Screen shift in points for a layer with multiplier 1.0 when your head is at the edge of its range.
    private let maxShift: CGFloat = 220

    // Movement multipliers of the laptop (fractions of maxShift). The classroom's layers have their own, all smaller
    // than these, in ClassroomLayout.multiplier(of:), so the further a thing is, the less it moves.
    private let laptopFocusMultiplier: CGFloat = 0.3
    private let laptopPeekMultiplier: CGFloat = 0.3

    /// In peek mode, where the laptop's top edge sits, as a fraction of the screen height from the bottom.
    private let peekLaptopTop: CGFloat = 0.2

    private let smoothing: CGFloat = 0.2             // easing of the head offset
    private let modeBlendSpeed: CGFloat = 0.12       // easing of the focus <-> peek transition

    // MARK: - Nodes and state

    /// The app's head tracking. Every frame the scene reads the head offset (-1...1 on each axis, +x = head right,
    /// +y = head up) and the pose to be in (focus or peek) from it.
    private let peek: PeekViewModel

    private let lecturer: LecturerViewModel
    private let topView: TopViewNode
    private let classroom: ClassroomNode

    private var smoothed: CGPoint = .zero
    private var blend: CGFloat = 0                   // 0 = focus pose, 1 = peek pose
    private var lastUpdate: TimeInterval = 0

    // MARK: - Setup

    init(lecturer: LecturerViewModel, peek: PeekViewModel) {
        self.peek = peek
        self.lecturer = lecturer
        let topView = TopViewNode(lecturer: lecturer)
        self.topView = topView
        classroom = ClassroomNode(topView: topView)
        super.init(size: CGSize(width: 900, height: 600))   // only a starting point: .resizeFill makes it match the SpriteView
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .white                // the sketch's plain white, behind every layer
        guard classroom.parent == nil else { return }

        addChild(classroom)
        layoutClassroom()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutClassroom()
    }

    /// The classroom sits at the middle of the screen, and its layers are scaled so the room covers the whole screen.
    private func layoutClassroom() {
        classroom.position = CGPoint(x: size.width / 2, y: size.height / 2)
        classroom.fit(to: size)
    }

    // MARK: - Parallax

    override func update(_ currentTime: TimeInterval) {
        // The lecturer walks on the scene's clock, the same way the minigame does.
        let dt = lastUpdate == 0 ? 0 : currentTime - lastUpdate
        lastUpdate = currentTime
        lecturer.update(deltaTime: dt)
        topView.sync()

        let headOffset = peek.headOffset
        smoothed.x += (headOffset.x - smoothed.x) * smoothing
        smoothed.y += (headOffset.y - smoothed.y) * smoothing

        let target: CGFloat = (peek.mode == .peek) ? 1 : 0
        blend += (target - blend) * modeBlendSpeed

        // Near layer (the laptop): centered in focus mode; in peek mode its top edge sits at `peekLaptopTop` of the screen height.
        let laptopPeekY = (peekLaptopTop - 0.5) * size.height - laptopSize.height / 2
        laptopOffset = shift(restY: lerp(0, laptopPeekY, blend),
                           multiplier: lerp(laptopFocusMultiplier, laptopPeekMultiplier, blend))

        // Far layers are drawn right here. Each one rests where the sketch puts it and slides by its own multiplier.
        for layer in ParallaxLayer.allCases {
            classroom.setShift(shift(restY: 0, multiplier: ClassroomLayout.multiplier(of: layer)), of: layer)
        }
    }

    /// Offset from the screen center = rest position - head offset * maxShift * multiplier.
    /// Head up -> layer slides down, and layers with a bigger multiplier slide more.
    private func shift(restY: CGFloat, multiplier: CGFloat) -> CGPoint {
        CGPoint(x: -smoothed.x * maxShift * multiplier,
                y: restY - smoothed.y * maxShift * multiplier)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}
