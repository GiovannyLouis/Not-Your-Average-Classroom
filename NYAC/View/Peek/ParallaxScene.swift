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
/// SpriteKit only draws the far layer. The near layer is the laptop, which is a SwiftUI view,
/// so the scene just works out where that view belongs (`wallOffset`) and the SwiftUI side follows it every frame.
final class ParallaxScene: SKScene {

    /// Normalized head offset, -1...1 (+x = head right, +y = head up). Set by the view model.
    var headOffset: CGPoint = .zero

    /// Which pose to be in. Set by the view model.
    var mode: HeadMode = .focus

    /// Size of the near layer (the laptop). The scene only needs it to know where the laptop's top edge sits in peek mode.
    var wallSize: CGSize = LaptopLayout.size

    /// Where the laptop's center is relative to the middle of the screen, in points.
    /// SpriteKit axes: +x = right, +y = UP. Updated every frame in `update`.
    private(set) var wallOffset: CGPoint = .zero

    // MARK: - Tuning

    /// Screen shift in points for a layer with multiplier 1.0 when your head is at the edge of its range.
    private let maxShift: CGFloat = 220

    // Movement multipliers (fractions of maxShift).
    private let wallFocusMultiplier: CGFloat = 0.25
    private let wallPeekMultiplier: CGFloat = 0.20
    private let dotMultiplier: CGFloat = 0.05      // keep it well below the wall's so depth still reads

    /// In peek mode, where the laptop's top edge sits, as a fraction of the screen height from the bottom.
    private let peekWallTop: CGFloat = 0.2

    private let smoothing: CGFloat = 0.2             // easing of the head offset
    private let modeBlendSpeed: CGFloat = 0.12       // easing of the focus <-> peek transition

    // MARK: - Nodes and state

    private let dot = SKShapeNode(circleOfRadius: 40)

    private var smoothed: CGPoint = .zero
    private var blend: CGFloat = 0                   // 0 = focus pose, 1 = peek pose

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.08, alpha: 1)
        guard dot.parent == nil else { return }

        // Far: Always at the screen center. Hidden behind the laptop in focus mode.
        dot.fillColor = .systemRed
        dot.strokeColor = .clear
        addChild(dot)
    }

    // MARK: - Parallax

    override func update(_ currentTime: TimeInterval) {
        smoothed.x += (headOffset.x - smoothed.x) * smoothing
        smoothed.y += (headOffset.y - smoothed.y) * smoothing

        let target: CGFloat = (mode == .peek) ? 1 : 0
        blend += (target - blend) * modeBlendSpeed

        // Near layer (the laptop): centered in focus mode; in peek mode its top edge sits at `peekWallTop` of the screen height.
        let wallPeekY = (peekWallTop - 0.5) * size.height - wallSize.height / 2
        wallOffset = shift(restY: lerp(0, wallPeekY, blend),
                           multiplier: lerp(wallFocusMultiplier, wallPeekMultiplier, blend))

        // Far layer is drawn right here.
        let dotShift = shift(restY: 0, multiplier: dotMultiplier)
        dot.position = CGPoint(x: size.width / 2 + dotShift.x,
                                 y: size.height / 2 + dotShift.y)
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
