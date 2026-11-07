//
//  TopViewNode.swift
//  NYAC
//
//  Created by Vrz on 04/11/26.
//

import SpriteKit

/// The classroom seen from above, drawn from plain shapes (no assets yet): whiteboard, the dashed walkway,
/// the four lecturer spots, the player's desk, and the lecturer's dot walking around.
/// It is the far layer of the parallax scene, so you only see it by peeking over the laptop.
///
/// Everything is laid out in TopViewLayout's units; the scene scales this node to fit.
final class TopViewNode: SKNode {

    private let lecturer: LecturerViewModel
    private let lecturerDot = SKShapeNode(circleOfRadius: TopViewLayout.lecturerRadius)
    private let lecturerLabel = SKLabelNode(text: "Lecturer")

    // Colors picked from the sketch.
    private let ink = SKColor.white
    private let panelColor = SKColor(white: 0.12, alpha: 1)
    private let spotColor = SKColor(red: 0.71, green: 0.62, blue: 0.25, alpha: 1)
    private let lecturerColor = SKColor(red: 0.76, green: 0.34, blue: 0.29, alpha: 1)
    private let playerColor = SKColor(red: 0.42, green: 0.66, blue: 0.40, alpha: 1)

    init(lecturer: LecturerViewModel) {
        self.lecturer = lecturer
        super.init()

        buildRoom()
        buildLecturer()
        sync()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    // MARK: - Every frame

    /// Moves the lecturer's dot to where the lecturer is right now. The scene calls this every frame.
    func sync() {
        let position: CGPoint
        switch lecturer.state {
        case .staying(let spot):
            position = TopViewLayout.position(of: spot)
        case .moving(let from, let to):
            position = TopViewLayout.point(along: TopViewLayout.route(from: from, to: to),
                                           at: CGFloat(lecturer.progress))
        }
        lecturerDot.position = position

        // Keep the name on the inside of the room, so it never runs off the panel.
        let gap = TopViewLayout.lecturerRadius + 12
        let onLeft = position.x < 0
        lecturerLabel.horizontalAlignmentMode = onLeft ? .left : .right
        lecturerLabel.position = CGPoint(x: onLeft ? gap : -gap, y: 0)
    }

    // MARK: - Drawing

    private func buildRoom() {
        // Panel behind everything
        let panel = SKShapeNode(rectOf: TopViewLayout.size, cornerRadius: TopViewLayout.cornerRadius)
        panel.fillColor = panelColor
        panel.strokeColor = SKColor(white: 1, alpha: 0.25)
        panel.lineWidth = 3
        panel.zPosition = 0
        addChild(panel)

        // The dashed walkway
        let loop = CGMutablePath()
        loop.addLines(between: TopViewLayout.walkway + [TopViewLayout.walkway[0]])
        let walkway = SKShapeNode(path: loop.copy(dashingWithPhase: 0, lengths: [18, 14]))
        outline(walkway, at: .zero)

        // Whiteboard
        let whiteboard = SKShapeNode(rectOf: TopViewLayout.whiteboardSize, cornerRadius: 6)
        outline(whiteboard, at: TopViewLayout.whiteboardCenter)
        addLabel("Whiteboard", at: TopViewLayout.whiteboardLabel)

        // The player's desk, with the laptop on it and the player behind it
        let desk = SKShapeNode(rectOf: TopViewLayout.deskSize, cornerRadius: 4)
        outline(desk, at: TopViewLayout.deskCenter)
        let laptop = SKShapeNode(rectOf: TopViewLayout.deskLaptopSize, cornerRadius: 3)
        outline(laptop, at: TopViewLayout.deskLaptopCenter)
        addDot(radius: TopViewLayout.playerRadius, color: playerColor, at: TopViewLayout.playerPosition, z: 3)
        addLabel("Player", at: TopViewLayout.playerLabel)

        // The four lecturer spots, each with its letter
        for spot in LecturerSpot.allCases {
            let position = TopViewLayout.position(of: spot)
            let offset = TopViewLayout.labelOffset(for: spot)
            addDot(radius: TopViewLayout.spotRadius, color: spotColor, at: position, z: 2)
            addLabel(spot.rawValue, at: CGPoint(x: position.x + offset.x, y: position.y + offset.y))
        }
    }

    private func buildLecturer() {
        lecturerDot.fillColor = lecturerColor
        lecturerDot.strokeColor = .clear
        lecturerDot.zPosition = 4

        lecturerLabel.fontName = "Helvetica"
        lecturerLabel.fontSize = 26
        lecturerLabel.fontColor = ink
        lecturerLabel.verticalAlignmentMode = .center
        lecturerDot.addChild(lecturerLabel)

        addChild(lecturerDot)
    }

    // MARK: - Small helpers

    private func outline(_ node: SKShapeNode, at position: CGPoint) {
        node.fillColor = .clear
        node.strokeColor = ink
        node.lineWidth = 4
        node.position = position
        node.zPosition = 1
        addChild(node)
    }

    private func addDot(radius: CGFloat, color: SKColor, at position: CGPoint, z: CGFloat) {
        let dot = SKShapeNode(circleOfRadius: radius)
        dot.fillColor = color
        dot.strokeColor = .clear
        dot.position = position
        dot.zPosition = z
        addChild(dot)
    }

    private func addLabel(_ text: String, at position: CGPoint) {
        let label = SKLabelNode(text: text)
        label.fontName = "Helvetica"
        label.fontSize = 30
        label.fontColor = ink
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = position
        label.zPosition = 5
        addChild(label)
    }
}
