//
//  ClassroomNode.swift
//  NYAC
//
//  Created by Vrz on 11/11/26.
//


import SpriteKit

/// The classroom as the player sees it from their seat, built as a greybox: plain boxes in the places of the sketch
/// (second row desks B C D, first row desks E F G, window H, door I, whiteboard J). The laptop is not part of it.
///
/// The room is split into one node per parallax layer. The scene slides each of those nodes by its own amount
/// (`setShift`), which is the whole parallax effect, while every item keeps its own z position for the draw order.
/// The top view of the classroom (the one with the lecturer in it) is mounted inside the whiteboard.
///
/// This node sits at the middle of the scene, and everything inside it is laid out in ClassroomLayout's design units.
final class ClassroomNode: SKNode {

    /// One container per parallax layer. Each is scaled to fit the scene and moved by its layer's shift.
    private var layerNodes: [ParallaxLayer: SKNode] = [:]

    // Greybox colors, picked from the sketch. They go away when the real art comes in.
    private let deskColor = SKColor(red: 0.60, green: 0.42, blue: 0.35, alpha: 1)
    private let windowColor = SKColor(white: 0.57, alpha: 1)
    private let doorColor = SKColor(red: 0.71, green: 0.59, blue: 0.42, alpha: 1)

    init(topView: TopViewNode) {
        super.init()

        for layer in ParallaxLayer.allCases {
            let node = SKNode()
            layerNodes[layer] = node
            addChild(node)
        }

        for item in ClassroomItem.allCases {
            build(item)
        }
        mount(topView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    // MARK: - Used by the scene

    /// Scales every layer so the room covers a scene of this size.
    func fit(to sceneSize: CGSize) {
        guard sceneSize.width > 0, sceneSize.height > 0 else { return }

        let scale = ClassroomLayout.scale(fitting: sceneSize)
        for node in layerNodes.values {
            node.setScale(scale)
        }
    }

    /// Slides one whole layer, in scene points, away from where the sketch puts it.
    /// Everything in the layer moves together, so they all keep the same speed.
    func setShift(_ shift: CGPoint, of layer: ParallaxLayer) {
        layerNodes[layer]?.position = shift
    }

    // MARK: - Building

    private func build(_ item: ClassroomItem) {
        let drawn = ClassroomLayout.drawnFrame(of: item)

        let box = SKShapeNode(rectOf: drawn.size)
        box.position = CGPoint(x: drawn.midX, y: drawn.midY)
        box.fillColor = fillColor(for: item)
        box.strokeColor = .black
        box.lineWidth = 3
        box.zPosition = ClassroomLayout.zPosition(of: item)
        layerNodes[item.layer]?.addChild(box)

        // The whiteboard carries the top view instead of a letter.
        guard ClassroomLayout.showsLetters, item != .whiteboard else { return }

        let label = SKLabelNode(text: item.letter)
        label.fontName = "Helvetica"
        label.fontSize = ClassroomLayout.letterSize(of: item)
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        // The label is a child of the box, so its position is relative to the box's center.
        // For an item that bleeds past the screen edge that is not the sketch's center, hence the conversion.
        let target = ClassroomLayout.letterPosition(of: item)
        label.position = CGPoint(x: target.x - drawn.midX, y: target.y - drawn.midY)
        label.zPosition = 1
        box.addChild(label)
    }

    /// Puts the top view inside the whiteboard, as big as the whiteboard lets it be.
    private func mount(_ topView: TopViewNode) {
        let inset = ClassroomLayout.whiteboardInset
        let board = ClassroomLayout.frame(of: .whiteboard).insetBy(dx: inset, dy: inset)
        let drawing = TopViewLayout.size

        topView.setScale(min(board.width / drawing.width, board.height / drawing.height))
        topView.position = CGPoint(x: board.midX, y: board.midY)
        topView.zPosition = ClassroomLayout.topViewZPosition
        layerNodes[.whiteboard]?.addChild(topView)
    }

    private func fillColor(for item: ClassroomItem) -> SKColor {
        switch item {
        case .secondRowLeft, .secondRowMiddle, .secondRowRight,
             .firstRowLeft, .firstRowMiddle, .firstRowRight:
            return deskColor
        case .window:
            return windowColor
        case .door:
            return doorColor
        case .whiteboard:
            return .white
        }
    }
}
