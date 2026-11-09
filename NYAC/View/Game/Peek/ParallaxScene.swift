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
/// SpriteKit only draws the far layer: the top view of the classroom, with the lecturer in it.
/// The near layer is the laptop, which is a SwiftUI view, so the scene just works out where that view
/// belongs (`wallOffset`) and the SwiftUI side follows it every frame.
final class ParallaxScene: SKScene {

    /// Size of the near layer (the laptop). The scene needs it to know where the laptop's top edge sits in peek mode,
    /// and how big the top view may be while still hiding completely behind the laptop in focus mode.
    var wallSize: CGSize = LaptopLayout.size {
        didSet { layoutTopView() }
    }

    /// Where the laptop's center is relative to the middle of the screen, in points.
    /// SpriteKit axes: +x = right, +y = UP. Updated every frame in `update`.
    private(set) var wallOffset: CGPoint = .zero

    // MARK: - Tuning

    /// Screen shift in points for a layer with multiplier 1.0 when your head is at the edge of its range.
    private let maxShift: CGFloat = 220

    // Movement multipliers (fractions of maxShift).
    private let wallFocusMultiplier: CGFloat = 0.25
    private let wallPeekMultiplier: CGFloat = 0.20
    private let topViewMultiplier: CGFloat = 0.05      // keep it well below the wall's so depth still reads

    /// In peek mode, where the laptop's top edge sits, as a fraction of the screen height from the bottom.
    private let peekWallTop: CGFloat = 0.2

    /// How tall the top view is, as a fraction of the screen height. It has to stay below 0.6, or in peek mode
    /// its bottom would still be hidden behind the laptop's top edge.
    private let topViewHeightFraction: CGFloat = 0.55

    private let smoothing: CGFloat = 0.2             // easing of the head offset
    private let modeBlendSpeed: CGFloat = 0.12       // easing of the focus <-> peek transition

    // MARK: - Nodes and state

    /// The app's head tracking. Every frame the scene reads the head offset (-1...1 on each axis, +x = head right,
    /// +y = head up) and the pose to be in (focus or peek) from it.
    private let peek: PeekViewModel

    private let lecturer: LecturerViewModel
    private let topView: TopViewNode

    private var smoothed: CGPoint = .zero
    private var blend: CGFloat = 0                   // 0 = focus pose, 1 = peek pose
    private var lastUpdate: TimeInterval = 0

    // MARK: - Setup

    init(lecturer: LecturerViewModel, peek: PeekViewModel) {
        self.peek = peek
        self.lecturer = lecturer
        topView = TopViewNode(lecturer: lecturer)
        super.init(size: CGSize(width: 900, height: 600))   // only a starting point: .resizeFill makes it match the SpriteView
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.08, alpha: 1)
        guard topView.parent == nil else { return }

        // Far: always at the screen center. Hidden behind the laptop in focus mode, so you have to peek to see it.
        addChild(topView)
        layoutTopView()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutTopView()
    }

    /// Big enough to read, but small enough to hide completely behind the laptop in focus mode.
    private func layoutTopView() {
        // The laptop and the top view slide by different amounts, so the laptop can drift this far off the top view's edge.
        let hideMargin = maxShift * abs(wallFocusMultiplier - topViewMultiplier) + 8

        let drawing = TopViewLayout.size
        let fitsBehindHeight = wallSize.height - 2 * hideMargin
        let fitsBehindWidth = (wallSize.width - 2 * hideMargin) * drawing.height / drawing.width

        let height = min(size.height * topViewHeightFraction, fitsBehindHeight, fitsBehindWidth)
        topView.setScale(max(height, 1) / drawing.height)
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

        // Near layer (the laptop): centered in focus mode; in peek mode its top edge sits at `peekWallTop` of the screen height.
        let wallPeekY = (peekWallTop - 0.5) * size.height - wallSize.height / 2
        wallOffset = shift(restY: lerp(0, wallPeekY, blend),
                           multiplier: lerp(wallFocusMultiplier, wallPeekMultiplier, blend))

        // Far layer is drawn right here.
        let topViewShift = shift(restY: 0, multiplier: topViewMultiplier)
        topView.position = CGPoint(x: size.width / 2 + topViewShift.x,
                                   y: size.height / 2 + topViewShift.y)
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
