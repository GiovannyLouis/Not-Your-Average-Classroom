//
//  MenuScene.swift
//  NYAC
//
//  Created by Vrz on 17/11/26.
//

import SpriteKit

/// The classroom behind the main screen: the wall, the board and the front row desks. The lobby and its settings
/// are drawn on the board by SwiftUI (see MenuView), so this scene only draws the room and moves it.
///
/// It is the game's parallax with the peek taken out: every frame each layer slides opposite to the head, by its own
/// speed (see MenuLayout). The wall does not move, like the game's background. There is no focus or peek here, so the
/// room always rests where the mock-up puts it.
///
/// Like in the classroom, every item is drawn with its art, and a plain box stands in for it while the project does not
/// have that image yet.
final class MenuScene: SKScene {

    /// Where the board is relative to its resting place, in points (SpriteKit axes: +x right, +y UP).
    /// Updated every frame in `update`. The text and the buttons on the board are SwiftUI, and they follow this.
    private(set) var boardShift: CGPoint = .zero

    // MARK: - Nodes and state

    /// The app's head tracking: the scene only reads the head offset (-1...1 on each axis) from it.
    private let peek: PeekViewModel

    /// The middle of the scene. The layers sit in it, in design units, and are scaled to fit the screen.
    private let root = SKNode()
    private let boardLayer = SKNode()
    private let deskLayer = SKNode()

    /// The wall picture. It stays nil (and the wall stays plain white) while the project has no background image.
    private var wallSprite: SKSpriteNode?
    
    /// A 20% black tint over the wall so its texture doesn't compete with the board and desks.
    private let wallDimNode = SKSpriteNode(color: .black, size: .zero)

    private var smoothed: CGPoint = .zero

    // Greybox colors, the same as the classroom's.
    private let deskColor = SKColor(red: 0.60, green: 0.42, blue: 0.35, alpha: 1)

    // MARK: - Setup

    init(peek: PeekViewModel) {
        self.peek = peek
        super.init(size: CGSize(width: 900, height: 600))   // only a starting point: .resizeFill makes it match the SpriteView
        scaleMode = .resizeFill
        backgroundColor = .white                            // the plain white of the mock, behind everything

        addChild(root)
        root.addChild(boardLayer)
        root.addChild(deskLayer)

        addWall()
        addWallDim()
        addBoard()
        for desk in MenuLayout.desks {
            addDesk(desk)
        }

        #if DEBUG
        // A typo in a file name shows up here: the item keeps its box (or the wall its white) and the name it was looking for is printed.
        var missing = ([MenuLayout.boardAssetName] + MenuLayout.desks.map(\.assetName)).filter { !imageExists($0) }
        if wallSprite == nil { missing.append(MenuLayout.wallAssetName) }
        if !missing.isEmpty {
            print("MenuScene: no image found for \(missing.joined(separator: ", ")), drawing the greybox / plain wall instead")
        }
        #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    // MARK: - Layout

    override func didMove(to view: SKView) {
        layoutRoom()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutRoom()
    }

    /// The room sits at the middle of the screen and is scaled to cover it, the same way the game's classroom is.
    private func layoutRoom() {
        guard size.width > 0, size.height > 0 else { return }

        root.position = CGPoint(x: size.width / 2, y: size.height / 2)
        wallDimNode.size = size

        let scale = ClassroomLayout.scale(fitting: size)
        boardLayer.setScale(scale)
        deskLayer.setScale(scale)

        // The wall keeps its proportions and grows until it covers the whole scene (what sticks out is cropped).
        if let sprite = wallSprite, let imageSize = sprite.texture?.size(), imageSize.width > 0, imageSize.height > 0 {
            let cover = max(size.width / imageSize.width, size.height / imageSize.height)
            sprite.size = CGSize(width: imageSize.width * cover, height: imageSize.height * cover)
        }
    }

    // MARK: - Parallax

    override func update(_ currentTime: TimeInterval) {
        let head = peek.headOffset
        smoothed.x += (head.x - smoothed.x) * MenuLayout.smoothing
        smoothed.y += (head.y - smoothed.y) * MenuLayout.smoothing

        boardShift = shift(multiplier: MenuLayout.boardMultiplier)
        boardLayer.position = boardShift
        deskLayer.position = shift(multiplier: MenuLayout.desksMultiplier)
    }

    /// Offset from the resting place = - head offset * maxShift * multiplier.
    /// Head up -> layer slides down, and layers with a bigger multiplier slide more.
    private func shift(multiplier: CGFloat) -> CGPoint {
        CGPoint(x: -smoothed.x * MenuLayout.maxShift * multiplier,
                y: -smoothed.y * MenuLayout.maxShift * multiplier)
    }

    // MARK: - Building
    
    /// Places a translucent black layer right in front of the wall and behind the board, desks, and UI.
    private func addWallDim() {
        wallDimNode.alpha = MenuLayout.wallDimOpacity
        wallDimNode.zPosition = (MenuLayout.wallZPosition + MenuLayout.boardZPosition) / 2
        root.addChild(wallDimNode)
    }

    /// Whether the project has the image yet.
    /// SKTexture never fails (a missing image becomes a placeholder picture), so AppKit is asked instead.
    /// It finds the image whether it sits in Assets.xcassets or is a loose file in the project.
    private func imageExists(_ name: String) -> Bool {
        NSImage(named: NSImage.Name(name)) != nil
    }

    /// The wall picture, if the project has one. Its size is set in `layoutRoom`, once the scene's size is known.
    private func addWall() {
        let name = MenuLayout.wallAssetName
        guard imageExists(name) else { return }

        let sprite = SKSpriteNode(texture: SKTexture(imageNamed: name))
        sprite.zPosition = MenuLayout.wallZPosition
        root.addChild(sprite)                   // not in a layer: it stays put behind everything
        wallSprite = sprite
    }

    /// The board: its art at `boardWidth` wide (as tall as its proportions make it), or a plain white board.
    private func addBoard() {
        let name = MenuLayout.boardAssetName

        if imageExists(name) {
            let texture = SKTexture(imageNamed: name)
            let imageSize = texture.size()
            let ratio = (imageSize.width > 0 && imageSize.height > 0)
                ? imageSize.height / imageSize.width
                : MenuLayout.greyboxBoardSize.height / MenuLayout.greyboxBoardSize.width

            let sprite = SKSpriteNode(texture: texture,
                                      size: CGSize(width: MenuLayout.boardWidth, height: MenuLayout.boardWidth * ratio))
            sprite.position = MenuLayout.boardCenter
            sprite.zPosition = MenuLayout.boardZPosition
            boardLayer.addChild(sprite)
        } else {
            let box = SKShapeNode(rectOf: MenuLayout.greyboxBoardSize)
            box.position = MenuLayout.boardCenter
            box.fillColor = .white
            box.strokeColor = .black
            box.lineWidth = 3
            box.zPosition = MenuLayout.boardZPosition
            boardLayer.addChild(box)
        }
    }

    /// One desk: its art at `deskWidth` wide with its top edge at `deskTop` (it runs down off the screen), or a plain box.
    private func addDesk(_ item: ClassroomItem) {
        let centerX = MenuLayout.deskCenterX(of: item)
        let name = item.assetName

        if imageExists(name) {
            let texture = SKTexture(imageNamed: name)
            let imageSize = texture.size()
            let ratio = (imageSize.width > 0 && imageSize.height > 0) ? imageSize.height / imageSize.width : 0.7
            let height = MenuLayout.deskWidth * ratio

            let sprite = SKSpriteNode(texture: texture, size: CGSize(width: MenuLayout.deskWidth, height: height))
            sprite.anchorPoint = CGPoint(x: 0.5, y: 1)          // pinned by its top edge
            sprite.position = CGPoint(x: centerX, y: MenuLayout.deskTop)
            sprite.zPosition = MenuLayout.deskZPosition(of: item)
            deskLayer.addChild(sprite)

            #if DEBUG
            // The desk has to reach past the bottom of the screen, also when the head lifts it. If it does not, a gap shows.
            let bottom = MenuLayout.deskTop - height
            let screenBottom = -ClassroomLayout.designSize.height / 2
            let liftRoom = MenuLayout.maxShift * MenuLayout.desksMultiplier * 2     // the most the head lifts it, in points, doubled to be safe in design units
            if bottom > screenBottom - liftRoom {
                print(String(format: "MenuScene: %@ ends at y %.0f but the screen's bottom is %.0f, so a gap can show under it (MenuLayout.deskWidth / deskTop)",
                             name, bottom, screenBottom))
            }
            #endif
        } else {
            let box = SKShapeNode(rectOf: CGSize(width: MenuLayout.deskWidth, height: MenuLayout.greyboxDeskHeight))
            box.position = CGPoint(x: centerX, y: MenuLayout.deskTop - MenuLayout.greyboxDeskHeight / 2)
            box.fillColor = deskColor
            box.strokeColor = .black
            box.lineWidth = 3
            box.zPosition = MenuLayout.deskZPosition(of: item)
            deskLayer.addChild(box)
        }
    }
}
