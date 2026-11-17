//
//  ClassroomNode.swift
//  NYAC
//
//  Created by Vrz on 11/11/26.
//

import SpriteKit

/// The classroom as the player sees it from their seat: second row desks B C D, first row desks E F G, window H,
/// door I and whiteboard J. The laptop is not part of it.
///
/// Every item is drawn with its art (named by `ClassroomItem.assetName`). While the project does not have that image
/// yet, the item is a greybox instead: a plain box with its sketch letter, in the same place. So a missing asset never
/// leaves a hole, and an item changes over by itself as soon as its image is added.
///
/// The room is split into one node per parallax layer. The scene slides each of those nodes by its own amount
/// (`setShift`), which is the whole parallax effect, while every item keeps its own z position for the draw order.
/// The top view of the classroom (the one with the lecturer in it) can be mounted inside the whiteboard, for debugging
/// the lecturer's movement. It is switched off for now: the `mount(topView)` line in `init` is commented out.
/// The lecturer himself (LecturerWalkNode) stands and walks in front of the whiteboard, in a layer of his own, because
/// his parallax speed changes while he walks toward the player, unlike the items'.
///
/// This node sits at the middle of the scene, and everything inside it is laid out in ClassroomLayout's design units.
final class ClassroomNode: SKNode {

    /// One container per parallax layer. Each is scaled to fit the scene and moved by its layer's shift.
    private var layerNodes: [ParallaxLayer: SKNode] = [:]

    /// The container of the lecturer. Like a layer node it is scaled to fit the scene and moved by its shift,
    /// but its speed is the scene's to set every frame (it changes while he walks), so it is not one of the ParallaxLayers.
    private let lecturerLayer = SKNode()

    /// The wall picture behind the room. It stays nil (and the wall stays plain white) while the project has no background image.
    private var backgroundSprite: SKSpriteNode?

    // Greybox colors, picked from the sketch. Only used for the items that do not have their art yet.
    private let deskColor = SKColor(red: 0.60, green: 0.42, blue: 0.35, alpha: 1)
    private let windowColor = SKColor(white: 0.57, alpha: 1)
    private let doorColor = SKColor(red: 0.71, green: 0.59, blue: 0.42, alpha: 1)

    init(topView: TopViewNode, lecturerWalk: LecturerWalkNode) {
        super.init()

        for layer in ParallaxLayer.allCases {
            let node = SKNode()
            layerNodes[layer] = node
            addChild(node)
        }
        addChild(lecturerLayer)
        lecturerLayer.addChild(lecturerWalk)      // its own zPosition puts him between the whiteboard and the first row desks

        addBackground()

        for item in ClassroomItem.allCases {
            if hasArt(item) {
                addArt(SKTexture(imageNamed: item.assetName), of: item)
            } else {
                addGreybox(item)
            }
        }

        // The top view on the whiteboard is switched off, now that the lecturer's walk is done. It is still all here:
        // uncomment the line below to see it again, for example to debug the lecturer's movement against it.
        // (ParallaxScene keeps feeding it every frame, so nothing else has to change.)
        
        // mount(topView)

        #if DEBUG
        // A typo in a file name shows up here: the item keeps its box (or the wall its white) and the name it was looking for is printed.
        var missing = ClassroomItem.allCases.filter { !hasArt($0) }.map(\.assetName)
        if backgroundSprite == nil { missing.append(ClassroomLayout.backgroundAssetName) }
        if !missing.isEmpty {
            print("ClassroomNode: no image found for \(missing.joined(separator: ", ")), drawing the greybox / plain wall instead")
        }
        #endif
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
        lecturerLayer.setScale(scale)

        // The wall picture keeps its proportions and grows until it covers the whole scene (what sticks out is cropped).
        // It is not part of any parallax layer: it stays put, at the middle of the scene, behind everything.
        if let sprite = backgroundSprite, let imageSize = sprite.texture?.size(), imageSize.width > 0, imageSize.height > 0 {
            let cover = max(sceneSize.width / imageSize.width, sceneSize.height / imageSize.height)
            sprite.size = CGSize(width: imageSize.width * cover, height: imageSize.height * cover)
        }
    }

    /// Slides one whole layer, in scene points, away from where the sketch puts it.
    /// Everything in the layer moves together, so they all keep the same speed.
    func setShift(_ shift: CGPoint, of layer: ParallaxLayer) {
        layerNodes[layer]?.position = shift
    }

    /// Slides the lecturer's container, in scene points. The scene works out its speed every frame (see LecturerWalkLayout.multiplier).
    func setLecturerShift(_ shift: CGPoint) {
        lecturerLayer.position = shift
    }

    // MARK: - Building

    /// Whether the project has the item's image yet.
    /// SKTexture never fails (a missing image becomes a placeholder picture), so AppKit is asked instead.
    /// It finds the image whether it sits in Assets.xcassets or is a loose file in the project.
    private func hasArt(_ item: ClassroomItem) -> Bool {
        imageExists(item.assetName)
    }

    private func imageExists(_ name: String) -> Bool {
        NSImage(named: NSImage.Name(name)) != nil
    }

    /// The wall picture, if the project has one. Its size is set in `fit(to:)`, once the scene's size is known.
    private func addBackground() {
        let name = ClassroomLayout.backgroundAssetName
        guard imageExists(name) else { return }

        let sprite = SKSpriteNode(texture: SKTexture(imageNamed: name))
        sprite.zPosition = ClassroomLayout.backgroundZPosition
        addChild(sprite)
        backgroundSprite = sprite
    }

    /// The item's art, stretched to exactly its `textureFrame`.
    private func addArt(_ texture: SKTexture, of item: ClassroomItem) {
        let frame = ClassroomLayout.textureFrame(of: item)

        let sprite = SKSpriteNode(texture: texture, size: frame.size)
        sprite.position = CGPoint(x: frame.midX, y: frame.midY)
        sprite.zPosition = ClassroomLayout.zPosition(of: item)
        layerNodes[item.layer]?.addChild(sprite)

        #if DEBUG
        // The art is stretched to fill its frame, so a picture with other proportions looks squashed. Say so.
        let imageSize = texture.size()
        if imageSize.width > 0, imageSize.height > 0, frame.height > 0 {
            let imageRatio = imageSize.width / imageSize.height
            let frameRatio = frame.width / frame.height
            if abs(imageRatio / frameRatio - 1) > 0.03 {
                print(String(format: "ClassroomNode: %@ is %.2f wide for its height, but its frame is %.2f, so it is stretched (ClassroomLayout.textureFrame)",
                             item.assetName, imageRatio, frameRatio))
            }
        }
        #endif
    }

    /// The box with the sketch's letter, drawn when the item has no art yet.
    private func addGreybox(_ item: ClassroomItem) {
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
