//
//  MinigameScene.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import SpriteKit
import AppKit

/// Pure renderer: every frame it advances the view model, then moves the pictures to match it.
///
/// Every picture (see MinigameLayout for the names and sizes) has a plain colored stand-in that is drawn while the
/// project does not have the picture yet, so the game stays playable with any of them missing.
final class MinigameScene: SKScene {

    // Smoothing knobs. Higher = snappier, lower = floatier. All of them are frame-rate independent.
    private let playerEase: CGFloat = 14           // how fast the drawn chicken closes the gap after a hop
    private let cameraEase: CGFloat = 8            // how fast the camera catches up with the chicken
    private let turnEase: CGFloat = 30             // how fast the chicken turns to face the way it hopped (very high = at once)

    private let viewModel: MinigameViewModel
    private let cell = MinigameLayout.cellSize

    private let laneLayer = SKNode()               // row backgrounds
    private let obstacleLayer = SKNode()           // cars and logs
    private let cameraNode = SKCameraNode()
    private let player = SKNode()                  // where the chicken is
    private let playerBody = SKNode()              // the chicken itself: this is what turns

    private var obstacleNodes: [UUID: SKNode] = [:]
    private var builtLevel = -1
    private var lastUpdate: TimeInterval = 0

    // The model hops instantly; the drawn chicken trails it by `playerOffset` (in points)
    // and that gap shrinks every frame.
    private var playerOffset = CGPoint.zero
    private var lastRow = 0
    private var lastX: CGFloat = 0

    /// The way the drawn chicken is turned right now. It follows `viewModel.facing` over a few frames.
    private var facingAngle: CGFloat = 0

    // Pictures found so far, and the names that were looked for and are not in the project (so AppKit is asked only once).
    private var textures: [String: SKTexture] = [:]
    private var missingArt: Set<String> = []

    private let carColors: [CarModel: SKColor] = [.car1: .systemBlue, .car2: .systemRed, .car3: .systemPurple]
    private let logColor = SKColor.brown

    init(viewModel: MinigameViewModel) {
        self.viewModel = viewModel
        super.init(size: MinigameLayout.size)

        backgroundColor = .black
        camera = cameraNode
        addChild(cameraNode)

        laneLayer.zPosition = 0
        obstacleLayer.zPosition = 1
        addChild(laneLayer)
        addChild(obstacleLayer)

        player.zPosition = 2
        player.addChild(playerBody)
        playerBody.addChild(makePlayerArt())
        addChild(player)

        rebuildLevel()

        #if DEBUG
        // A typo in a file name shows up here: that picture keeps its stand-in and the name it was looking for is printed.
        let missing = MinigameLayout.allAssetNames.filter { art(named: $0) == nil }
        if !missing.isEmpty {
            print("MinigameScene: no image found for \(missing.joined(separator: ", ")), drawing plain shapes instead")
        }
        #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    // MARK: - Frame loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : currentTime - lastUpdate
        lastUpdate = currentTime

        viewModel.update(deltaTime: dt)

        if builtLevel != viewModel.levelVersion { rebuildLevel() }
        syncObstacles()
        syncPlayer(deltaTime: dt)
        followPlayer(deltaTime: dt)
    }

    // MARK: - Pictures

    /// The picture with this name, or nil while the project does not have it.
    /// SKTexture never fails (a missing image becomes a placeholder picture), so AppKit is asked instead.
    /// It finds the image whether it sits in Assets.xcassets or is a loose file in the project.
    private func art(named name: String) -> SKTexture? {
        if let known = textures[name] { return known }
        guard !missingArt.contains(name) else { return nil }

        guard NSImage(named: NSImage.Name(name)) != nil else {
            missingArt.insert(name)
            return nil
        }
        let texture = SKTexture(imageNamed: name)
        textures[name] = texture
        return texture
    }

    /// Width divided by height of the picture, or nil if it has no size.
    private func widthPerHeight(of texture: SKTexture) -> CGFloat? {
        let size = texture.size()
        guard size.width > 0, size.height > 0 else { return nil }
        return size.width / size.height
    }

    // MARK: - Level

    private func rebuildLevel() {
        builtLevel = viewModel.levelVersion

        laneLayer.removeAllChildren()
        obstacleLayer.removeAllChildren()
        obstacleNodes.removeAll()

        // One picture per row, placed once. Nothing about a row changes while the level runs.
        for (index, row) in viewModel.rows.enumerated() {
            let lane = makeLane(for: row)
            lane.position = CGPoint(x: size.width / 2, y: (CGFloat(index) + 0.5) * cell)
            laneLayer.addChild(lane)
        }

        // A new run starts from scratch: no glide from the old spot, no turn from the old facing, camera snaps into place.
        lastRow = viewModel.playerRow
        lastX = viewModel.playerX
        playerOffset = .zero
        player.position = playerBasePosition()
        facingAngle = MinigameLayout.facingAngle(of: viewModel.facing)
        playerBody.zRotation = facingAngle
        cameraNode.position = CGPoint(x: size.width / 2, y: cameraTargetY())
    }

    /// The row's picture, stretched to exactly the row's width and one cell tall (plus the little overlap, see MinigameLayout).
    /// The stand-in is a plain color.
    private func makeLane(for row: Row) -> SKSpriteNode {
        let laneSize = CGSize(width: size.width, height: cell + MinigameLayout.rowOverlap)
        let name = MinigameLayout.assetName(for: row)

        guard let texture = art(named: name) else {
            return SKSpriteNode(color: laneColor(for: row.type), size: laneSize)
        }

        #if DEBUG
        // The picture is stretched to fill the row, so one with other proportions looks squashed. Say so, once.
        if let aspect = widthPerHeight(of: texture), !checkedRowArt.contains(name) {
            checkedRowArt.insert(name)
            let expected = size.width / cell
            if abs(aspect / expected - 1) > 0.03 {
                print(String(format: "MinigameScene: %@ is %.2f wide for its height, but a row is %.2f, so it is stretched (MinigameLayout)",
                             name, aspect, expected))
            }
        }
        #endif

        return SKSpriteNode(texture: texture, size: laneSize)
    }

    #if DEBUG
    private var checkedRowArt: Set<String> = []
    #endif

    private func laneColor(for type: RowType) -> SKColor {
        switch type {
        case .road:  return SKColor.black
        case .river: return SKColor(red: 0.10, green: 0.40, blue: 0.85, alpha: 1)
        case .safe:  return SKColor(red: 0.22, green: 0.65, blue: 0.28, alpha: 1)
        }
    }

    // MARK: - Syncing pictures with the model

    private func syncObstacles() {
        var alive = Set<UUID>()

        for (index, row) in viewModel.rows.enumerated() where row.type != .safe {
            let y = (CGFloat(index) + 0.5) * cell
            for obstacle in row.obstacles {
                alive.insert(obstacle.id)
                let node = obstacleNodes[obstacle.id] ?? makeNode(for: obstacle, in: row)
                node.position = CGPoint(x: obstacle.x * cell, y: y)
            }
        }

        // Remove pictures whose obstacle has left the field.
        for (id, node) in obstacleNodes where !alive.contains(id) {
            node.removeFromParent()
            obstacleNodes[id] = nil
        }
    }

    private func makeNode(for obstacle: Obstacle, in row: Row) -> SKNode {
        let node: SKNode
        if row.type == .road {
            node = makeCar(of: row.car ?? .car1, width: obstacle.width, direction: row.direction)
        } else {
            node = makeLog(width: obstacle.width)
        }
        obstacleLayer.addChild(node)
        obstacleNodes[obstacle.id] = node
        return node
    }

    /// The row's car, as wide as the model says it is (that is what it collides with), as tall as the picture's
    /// proportions make it, and mirrored when it drives the other way than the picture does.
    private func makeCar(of model: CarModel, width: CGFloat, direction: LaneDirection) -> SKNode {
        let points = width * cell

        guard let texture = art(named: MinigameLayout.assetName(for: model)), let aspect = widthPerHeight(of: texture) else {
            return SKSpriteNode(color: carColors[model] ?? .systemBlue, size: CGSize(width: points, height: cell * 0.7))
        }

        let sprite = SKSpriteNode(texture: texture, size: CGSize(width: points, height: points / aspect))
        if direction != MinigameLayout.carArtFaces { sprite.xScale = -1 }
        return sprite
    }

    /// A log is the one-cell log picture repeated side by side, once for every cell of its length (2, 3 or 4).
    private func makeLog(width: CGFloat) -> SKNode {
        let tiles = max(1, Int(width.rounded()))
        let points = CGFloat(tiles) * cell

        guard let texture = art(named: MinigameLayout.logAssetName), let aspect = widthPerHeight(of: texture) else {
            return SKSpriteNode(color: logColor, size: CGSize(width: points, height: cell * 0.7))
        }

        let log = SKNode()
        let tileSize = CGSize(width: cell + MinigameLayout.tileOverlap, height: cell / aspect)
        for index in 0..<tiles {
            let tile = SKSpriteNode(texture: texture, size: tileSize)
            tile.position = CGPoint(x: -points / 2 + (CGFloat(index) + 0.5) * cell, y: 0)
            log.addChild(tile)
        }
        return log
    }

    // MARK: - The chicken

    /// The chicken's picture, `playerHeight` tall, facing up. The stand-in is a white circle with a little beak,
    /// so that which way it faces can be seen before the picture exists.
    private func makePlayerArt() -> SKNode {
        if let texture = art(named: MinigameLayout.playerAssetName), let aspect = widthPerHeight(of: texture) {
            let height = MinigameLayout.playerHeight
            return SKSpriteNode(texture: texture, size: CGSize(width: height * aspect, height: height))
        }

        let radius = cell * 0.35
        let body = SKShapeNode(circleOfRadius: radius)
        body.fillColor = .white
        body.strokeColor = .clear

        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: -radius * 0.35, y: radius * 0.85))
        beakPath.addLine(to: CGPoint(x: radius * 0.35, y: radius * 0.85))
        beakPath.addLine(to: CGPoint(x: 0, y: radius * 1.4))
        beakPath.closeSubpath()
        let beak = SKShapeNode(path: beakPath)
        beak.fillColor = .orange
        beak.strokeColor = .clear
        body.addChild(beak)

        return body
    }

    /// Where the chicken really is according to the model.
    private func playerBasePosition() -> CGPoint {
        CGPoint(x: viewModel.playerX * cell,
                y: (CGFloat(viewModel.playerRow) + 0.5) * cell)
    }

    private func syncPlayer(deltaTime dt: TimeInterval) {
        let row = viewModel.playerRow
        let x = viewModel.playerX

        // A hop moves the model by a whole cell in one frame. Instead of teleporting the picture,
        // keep it where it was and let the gap close over the next few frames. A log only drifts
        // a few hundredths of a cell per frame, which is far below the threshold, so riding a
        // log is followed 1:1 and never lags.
        let hopped = row != lastRow || abs(x - lastX) > 0.25
        if hopped {
            playerOffset.x += (lastX - x) * cell
            playerOffset.y += CGFloat(lastRow - row) * cell
        }
        lastRow = row
        lastX = x

        let decay = exp(-playerEase * CGFloat(dt))
        playerOffset.x *= decay
        playerOffset.y *= decay

        let base = playerBasePosition()
        player.position = CGPoint(x: base.x + playerOffset.x, y: base.y + playerOffset.y)

        // Turn toward the way the chicken last hopped, the short way round (a half turn goes either way, never more).
        let target = MinigameLayout.facingAngle(of: viewModel.facing)
        let difference = target - facingAngle
        let shortest = atan2(sin(difference), cos(difference))
        facingAngle += shortest * (1 - exp(-turnEase * CGFloat(dt)))
        playerBody.zRotation = facingAngle
    }

    // MARK: - Camera

    /// Keeps the chicken a few rows above the bottom edge and never shows outside the level.
    /// It follows the *drawn* chicken, so the camera starts moving smoothly with it.
    private func cameraTargetY() -> CGFloat {
        let halfHeight = size.height / 2
        let highest = CGFloat(viewModel.rows.count) * cell - halfHeight
        return min(max(player.position.y + cell * 3, halfHeight), highest)
    }

    private func followPlayer(deltaTime dt: TimeInterval) {
        let blend = 1 - exp(-cameraEase * CGFloat(dt))
        cameraNode.position.y += (cameraTargetY() - cameraNode.position.y) * blend
    }
}
