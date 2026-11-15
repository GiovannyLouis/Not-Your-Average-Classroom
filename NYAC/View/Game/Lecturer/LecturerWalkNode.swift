//
//  LecturerWalkNode.swift
//  NYAC
//
//  Created by Vrz on 15/11/26.
//


import SpriteKit

/// The lecturer as a figure in the classroom: the sprite that stands at B or C and walks to the next spot.
/// While the lecturer is at A or D (or walking between them) he is behind the player, so nothing is shown.
///
/// This node only draws. Where he is and how far through his walk he is comes from LecturerViewModel,
/// and where the sprite goes, how big it is and how it looks is worked out by LecturerWalkLayout.
/// The scene calls `sync()` every frame, the same way it does for the top view.
///
/// The sprite is placed by its feet: the node's position is the middle of the sprite's bottom edge, its scale is the
/// sprite's size, and flipping the node's x scale mirrors it. ClassroomNode mounts this node, and everything in it is
/// in the classroom's design units.
///
/// Art: `lecturer.png` (facing the player) and `lecturer_back.png` (facing away). While the project does not have
/// them, a greybox figure with the word "front" or "back" stands in, so the walks can be tested before the art is in.
final class LecturerWalkNode: SKNode {

    static let frontAssetName = "lecturer"
    static let backAssetName = "lecturer_back"

    private let lecturer: LecturerViewModel

    /// The figure facing the player and the one facing away. Only one is shown at a time.
    private let front: SKNode
    private let back: SKNode

    /// How far along the walk toward the player he is (0 at B or C, 1 at A or D), for the parallax speed. 0 when he is hidden.
    private(set) var closeness: CGFloat = 0

    init(lecturer: LecturerViewModel) {
        self.lecturer = lecturer

        let hasFront = LecturerWalkNode.imageExists(LecturerWalkNode.frontAssetName)
        let hasBack = LecturerWalkNode.imageExists(LecturerWalkNode.backAssetName)

        front = hasFront ? LecturerWalkNode.sprite(named: LecturerWalkNode.frontAssetName) : LecturerWalkNode.greybox(label: "front")
        // The back view may be drawn later than the front view. Until then he walks away facing the player.
        back = hasBack ? LecturerWalkNode.sprite(named: LecturerWalkNode.backAssetName)
                       : (hasFront ? LecturerWalkNode.sprite(named: LecturerWalkNode.frontAssetName) : LecturerWalkNode.greybox(label: "back"))

        super.init()

        addChild(front)
        addChild(back)
        sync()

        #if DEBUG
        // A typo in a file name shows up here: the figure keeps its box (or the front sprite) and the name it was looking for is printed.
        var missing: [String] = []
        if !hasFront { missing.append(LecturerWalkNode.frontAssetName) }
        if !hasBack { missing.append(LecturerWalkNode.backAssetName) }
        if !missing.isEmpty {
            print("LecturerWalkNode: no image found for \(missing.joined(separator: ", ")), drawing a stand-in instead")
        }
        #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    // MARK: - Every frame

    /// Puts the lecturer where he is right now. The scene calls this every frame.
    func sync() {
        guard let pose = LecturerWalkLayout.pose(for: lecturer.state, progress: CGFloat(lecturer.progress)) else {
            isHidden = true
            closeness = 0
            return
        }

        isHidden = false
        position = CGPoint(x: pose.feet.x, y: pose.feet.y + pose.lift)
        xScale = pose.isMirrored ? -pose.scale : pose.scale
        yScale = pose.scale
        zPosition = pose.z
        front.isHidden = pose.facing != .front
        back.isHidden = pose.facing != .back
        closeness = pose.closeness
    }

    // MARK: - Building

    /// Whether the project has the image yet.
    /// SKTexture never fails (a missing image becomes a placeholder picture), so AppKit is asked instead.
    private static func imageExists(_ name: String) -> Bool {
        NSImage(named: NSImage.Name(name)) != nil
    }

    /// The art, `LecturerWalkLayout.height` tall, with its feet (the middle of its bottom edge) at the node's origin.
    private static func sprite(named name: String) -> SKNode {
        let texture = SKTexture(imageNamed: name)
        let imageSize = texture.size()
        let aspect = (imageSize.width > 0 && imageSize.height > 0) ? imageSize.width / imageSize.height : LecturerWalkLayout.aspect
        let height = LecturerWalkLayout.height

        let node = SKSpriteNode(texture: texture, size: CGSize(width: height * aspect, height: height))
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        return node
    }

    /// A paper-doll stand-in, drawn with the same proportions as lecturer.png, with the word of the view it stands in for.
    /// The word is mirrored together with the figure, which makes it easy to see when the sprite is flipped.
    private static func greybox(label text: String) -> SKNode {
        let height = LecturerWalkLayout.height
        let width = height * LecturerWalkLayout.aspect
        let node = SKNode()

        let body = SKShapeNode(rect: CGRect(x: -width * 0.36, y: height * 0.06, width: width * 0.72, height: height * 0.69),
                               cornerRadius: width * 0.2)
        body.fillColor = SKColor(red: 0.04, green: 0.07, blue: 0.45, alpha: 1)
        body.strokeColor = .black
        body.lineWidth = 4
        node.addChild(body)

        let head = SKShapeNode(ellipseOf: CGSize(width: width * 0.44, height: height * 0.25))
        head.position = CGPoint(x: 0, y: height * 0.84)
        head.fillColor = SKColor(red: 0.96, green: 0.76, blue: 0.40, alpha: 1)
        head.strokeColor = .black
        head.lineWidth = 4
        head.zPosition = 1
        node.addChild(head)

        let label = SKLabelNode(text: text)
        label.fontName = "Helvetica"
        label.fontSize = height * 0.07
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: height * 0.4)
        label.zPosition = 2
        node.addChild(label)

        return node
    }
}
