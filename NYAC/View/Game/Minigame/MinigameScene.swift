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
/// Every picture (see MinigameLayout for the names, sizes and timings) has a plain stand-in that is drawn while the
/// project does not have the picture yet, so the game stays playable with any of them missing.
final class MinigameScene: SKScene {

    // Smoothing knobs. Higher = snappier, lower = floatier. All of them are frame-rate independent.
    private let playerEase: CGFloat = 14           // how fast the drawn cat closes the gap after a hop
    private let cameraEase: CGFloat = 8            // how fast the camera catches up with the cat
    private let turnEase: CGFloat = 30             // how fast the cat turns to face the way it hopped (very high = at once)

    /// How long a hop lasts on screen: about the time the glide above takes to close the gap (3.5 / playerEase).
    /// The jump picture is shown, and the cat grows and shrinks again, for exactly this long.
    private var jumpDuration: TimeInterval { TimeInterval(3.5 / playerEase) }

    private let viewModel: MinigameViewModel
    private let cell = MinigameLayout.cellSize

    /// Front to back: the cars cover the cat, the cat covers the logs, and the logs cover the river. A drowning cat goes
    /// under the logs (but still over the river, so it can be seen).
    private enum Layer {
        static let lane: CGFloat = 0
        static let drowningPlayer: CGFloat = 0.5
        static let log: CGFloat = 1
        static let player: CGFloat = 2
        static let car: CGFloat = 3
    }

    private let laneLayer = SKNode()               // row backgrounds
    private let logLayer = SKNode()                // logs
    private let carLayer = SKNode()                // cars
    private let cameraNode = SKCameraNode()
    private let player = SKNode()                  // where the cat is
    private let playerBody = SKNode()              // the cat itself: this is what turns, spins and grows
    private let catSprite = SKSpriteNode()         // its picture, swapped for every frame of every animation
    private let standIn = SKNode()                 // a white circle with a beak, for as long as there is no picture at all

    private var obstacleNodes: [UUID: SKNode] = [:]
    private var builtLevel = -1
    private var lastUpdate: TimeInterval = 0

    // The model hops instantly; the drawn cat trails it by `playerOffset` (in points)
    // and that gap shrinks every frame.
    private var playerOffset = CGPoint.zero
    private var lastRow = 0
    private var lastX: CGFloat = 0

    /// The way the drawn cat is turned right now. It follows `viewModel.facing` over a few frames.
    private var facingAngle: CGFloat = 0

    // The cat's animations. The clocks restart with every run.
    private var catUnit: CGFloat = 1               // points per point of picture: makes mcidle_1 `playerHeight` tall
    private var catPictureSize = CGSize.zero       // the picture showing now, at full size (before any flattening)
    private var idleFrames: [SKTexture] = []
    private var jumpFrame: SKTexture?
    private var drownFrames: [SKTexture] = []
    private var hitFrame: SKTexture?
    private var winFrames: [SKTexture] = []

    private var jumpTime: TimeInterval = .greatestFiniteMagnitude    // seconds since the last hop started
    private var idleClock: TimeInterval = 0                          // seconds since the cat last stood still
    private var outcomeTime: TimeInterval = 0                        // seconds since the run ended
    private var crashPlaced = false                                  // whether the cat has been put on its car yet
    private var spin: CGFloat = 0                                    // how far the winning cat has turned (clockwise = negative)

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

        laneLayer.zPosition = Layer.lane
        logLayer.zPosition = Layer.log
        carLayer.zPosition = Layer.car
        addChild(laneLayer)
        addChild(logLayer)
        addChild(carLayer)

        player.zPosition = Layer.player
        player.addChild(playerBody)
        playerBody.addChild(standIn)
        playerBody.addChild(catSprite)
        addChild(player)

        buildStandIn()
        loadCat()
        rebuildLevel()

        #if DEBUG
        // A typo in a file name shows up here: that picture keeps its stand-in and the name it was looking for is printed.
        let missing = MinigameLayout.allAssetNames.filter { art(named: $0) == nil }
        if !missing.isEmpty {
            print("MinigameScene: no image found for \(missing.joined(separator: ", ")), drawing something plain instead")
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

    /// The pictures of an animation that the project has, in order.
    private func frames(of names: [String]) -> [SKTexture] {
        names.compactMap { art(named: $0) }
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
        logLayer.removeAllChildren()
        carLayer.removeAllChildren()
        obstacleNodes.removeAll()

        // One picture per row, placed once. Nothing about a row changes while the level runs.
        let count = viewModel.rows.count
        for (index, row) in viewModel.rows.enumerated() {
            let lane = makeLane(for: row, at: index, of: count)
            lane.position = CGPoint(x: size.width / 2, y: (CGFloat(index) + 0.5) * cell)
            laneLayer.addChild(lane)
        }

        // A new run starts from scratch: no glide from the old spot, no turn from the old facing, the cat is back
        // and standing, and the camera snaps into place.
        lastRow = viewModel.playerRow
        lastX = viewModel.playerX
        playerOffset = .zero
        player.position = playerBasePosition()
        player.isHidden = false
        player.zPosition = Layer.player
        facingAngle = MinigameLayout.facingAngle(of: viewModel.facing)
        playerBody.zRotation = facingAngle
        playerBody.setScale(1)
        jumpTime = .greatestFiniteMagnitude
        idleClock = 0
        outcomeTime = 0
        crashPlaced = false
        spin = 0
        show(idleFrames.first)
        cameraNode.position = CGPoint(x: size.width / 2, y: cameraTargetY())
    }

    /// The row's picture, stretched to exactly the row's width and one cell tall (plus the little overlap, see MinigameLayout).
    /// The stand-in is a plain color. The start and end row fall back to grass.
    private func makeLane(for row: Row, at index: Int, of count: Int) -> SKSpriteNode {
        let laneSize = CGSize(width: size.width, height: cell + MinigameLayout.rowOverlap)
        let name = MinigameLayout.assetName(for: row, at: index, of: count)

        let found = art(named: name)
        guard let texture = found ?? (row.type == .safe ? art(named: MinigameLayout.grassAssetName) : nil) else {
            return SKSpriteNode(color: laneColor(for: row.type), size: laneSize)
        }

        #if DEBUG
        // The picture is stretched to fill the row, so one with other proportions looks squashed. Say so, once.
        if found != nil, let aspect = widthPerHeight(of: texture), !checkedRowArt.contains(name) {
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
            carLayer.addChild(node)
        } else {
            node = makeLog(width: obstacle.width)
            logLayer.addChild(node)
        }
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

    // MARK: - The cat: pictures

    private let standInSize = CGSize(width: MinigameLayout.cellSize * 0.7, height: MinigameLayout.cellSize * 0.7)

    /// Finds the cat's pictures. Whatever is missing falls back to something else: no jump picture shows the idle one,
    /// no idle pictures show mc, and with nothing at all the stand-in is drawn.
    private func loadCat() {
        idleFrames = frames(of: MinigameLayout.idleAssetNames)
        if idleFrames.isEmpty, let still = art(named: MinigameLayout.playerAssetName) { idleFrames = [still] }
        jumpFrame = art(named: MinigameLayout.jumpAssetName)
        drownFrames = frames(of: MinigameLayout.drownAssetNames)
        hitFrame = art(named: MinigameLayout.hitAssetName)
        winFrames = frames(of: MinigameLayout.winAssetNames)

        // One scale for all of them, from the first idle picture, so that they keep their sizes next to each other.
        if let reference = idleFrames.first, reference.size().height > 0 {
            catUnit = MinigameLayout.playerHeight / reference.size().height
        }
    }

    /// The stand-in is a white circle with a little beak, so that which way the cat faces can be seen before the pictures exist.
    private func buildStandIn() {
        let radius = standInSize.width / 2
        let body = SKShapeNode(circleOfRadius: radius)
        body.fillColor = .white
        body.strokeColor = .clear
        standIn.addChild(body)

        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: -radius * 0.35, y: radius * 0.85))
        beakPath.addLine(to: CGPoint(x: radius * 0.35, y: radius * 0.85))
        beakPath.addLine(to: CGPoint(x: 0, y: radius * 1.4))
        beakPath.closeSubpath()
        let beak = SKShapeNode(path: beakPath)
        beak.fillColor = .orange
        beak.strokeColor = .clear
        standIn.addChild(beak)
    }

    /// Shows this picture of the cat, flattened along the way it faces by `flatten` (1 = not flattened).
    /// Nil shows the stand-in.
    ///
    /// The flattening is done on the picture's size, never on the sprite's scale, and the size is set again on every
    /// call. The sprite's own scale stays 1 for good, so no leftover from a flat cat can follow it into the next run.
    private func show(_ texture: SKTexture?, flatten: CGFloat = 1) {
        standIn.yScale = flatten

        guard let texture else {
            catSprite.isHidden = true
            standIn.isHidden = false
            catPictureSize = standInSize
            return
        }

        standIn.isHidden = true
        catSprite.isHidden = false
        if catSprite.texture !== texture { catSprite.texture = texture }

        let natural = texture.size()
        catPictureSize = CGSize(width: natural.width * catUnit, height: natural.height * catUnit)
        catSprite.size = CGSize(width: catPictureSize.width, height: catPictureSize.height * flatten)
    }

    /// The picture of a looping animation at this time.
    private func looping(_ frames: [SKTexture], at time: TimeInterval, every duration: TimeInterval) -> SKTexture? {
        guard !frames.isEmpty, duration > 0 else { return frames.first }
        return frames[Int(time / duration) % frames.count]
    }

    /// The picture of an animation that plays once at this time, and stays on its last picture.
    private func playing(_ frames: [SKTexture], at time: TimeInterval, every duration: TimeInterval) -> SKTexture? {
        guard !frames.isEmpty, duration > 0 else { return frames.first }
        return frames[min(Int(time / duration), frames.count - 1)]
    }

    // MARK: - The cat: where it is and what it does

    /// Where the cat really is according to the model.
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
            jumpTime = 0
            idleClock = 0
        }
        lastRow = row
        lastX = x

        let decay = exp(-playerEase * CGFloat(dt))
        playerOffset.x *= decay
        playerOffset.y *= decay

        // Turn toward the way the cat last hopped, the short way round (a half turn goes either way, never more).
        let target = MinigameLayout.facingAngle(of: viewModel.facing)
        let difference = target - facingAngle
        let shortest = atan2(sin(difference), cos(difference))
        facingAngle += shortest * (1 - exp(-turnEase * CGFloat(dt)))
        playerBody.zRotation = facingAngle

        // A cat that goes under the water goes under the logs too.
        player.zPosition = viewModel.state == .ended(.drowned) ? Layer.drowningPlayer : Layer.player

        switch viewModel.state {
        case .ready, .playing:
            showAlive(deltaTime: dt)
        case .ended(let outcome):
            outcomeTime += dt
            switch outcome {
            case .won:      showWon(deltaTime: dt)
            case .drowned:  showDrowned()
            case .hitByCar: showCrashed(facing: target)
            }
        }
    }

    /// Puts the cat at its model position (plus whatever is left of the glide from where it hopped from).
    private func placeAtModelPosition() {
        let base = playerBasePosition()
        player.position = CGPoint(x: base.x + playerOffset.x, y: base.y + playerOffset.y)
    }

    /// Standing: the idle pictures one after the other. Hopping: the jump picture, and the cat grows to
    /// `jumpScale` in the middle of the hop and back to 1 as it lands.
    private func showAlive(deltaTime dt: TimeInterval) {
        jumpTime += dt
        idleClock += dt

        if jumpTime < jumpDuration {
            show(jumpFrame ?? idleFrames.first)
            let progress = CGFloat(jumpTime / jumpDuration)                    // 0 as it leaves, 1 as it lands
            playerBody.setScale(1 + (MinigameLayout.jumpScale - 1) * sin(.pi * progress))
        } else {
            show(looping(idleFrames, at: idleClock, every: MinigameLayout.idleFrameDuration))
            playerBody.setScale(1)
        }
        placeAtModelPosition()
    }

    /// Won: the win pictures, and the cat spins clockwise for as long as the world runs.
    private func showWon(deltaTime dt: TimeInterval) {
        spin = (spin - 2 * .pi / MinigameLayout.winSpinPeriod * CGFloat(dt)).truncatingRemainder(dividingBy: 2 * .pi)

        show(looping(winFrames.isEmpty ? idleFrames : winFrames, at: outcomeTime, every: MinigameLayout.winFrameDuration))
        playerBody.setScale(1)
        playerBody.zRotation = facingAngle + spin
        placeAtModelPosition()
    }

    /// Drowned: the drown pictures once, where the cat went under and facing the way it hopped, then it is gone.
    private func showDrowned() {
        let duration = TimeInterval(MinigameLayout.drownAssetNames.count) * MinigameLayout.drownFrameDuration
        guard outcomeTime < duration else {
            player.isHidden = true
            return
        }

        show(playing(drownFrames.isEmpty ? idleFrames : drownFrames, at: outcomeTime, every: MinigameLayout.drownFrameDuration))
        playerBody.setScale(1)
        placeAtModelPosition()
    }

    /// Hit by a car: mchit.
    /// From the front the cat is flattened into the road: mchit as it is, staying where it was hit while the car drives over it.
    /// From the side or the back it is flattened against the car: mchit flattened along the way the cat faces, stuck to the
    /// car that hit it and carried along until the restart.
    private func showCrashed(facing angle: CGFloat) {
        guard let crash = viewModel.crash else {
            player.isHidden = true
            return
        }

        let flatten = crash.side == .front ? 1 : MinigameLayout.flattenScale
        show(hitFrame ?? idleFrames.first, flatten: flatten)
        playerBody.setScale(1)

        // On the road: it stays where the model says it is.
        guard crash.side != .front else {
            placeAtModelPosition()
            return
        }

        // On the car.
        guard let car = obstacleNodes[crash.obstacleID] as? SKSpriteNode,      // the car is gone once it has left the field
              viewModel.rows.indices.contains(viewModel.playerRow) else {
            player.isHidden = true
            return
        }

        let direction = viewModel.rows[viewModel.playerRow].direction
        let pinned = pinnedPosition(for: crash, car: car, direction: direction,
                                    cat: catPictureSize, flatten: flatten, facing: angle)

        // The first frame the cat leaves where it was and slides on to the car, instead of jumping there.
        if !crashPlaced {
            crashPlaced = true
            let base = playerBasePosition()
            playerOffset.x += base.x - pinned.x
            playerOffset.y += base.y - pinned.y
        }
        player.position = CGPoint(x: pinned.x + playerOffset.x, y: pinned.y + playerOffset.y)
    }

    /// Where the cat's center goes so that it touches the part of the car it ran into (and moves with the car).
    /// `cat` is the picture's size before flattening; its flattened, turned shape decides how far from the car's edge it sits.
    private func pinnedPosition(for crash: Crash, car: SKSpriteNode, direction: LaneDirection,
                                cat: CGSize, flatten: CGFloat, facing angle: CGFloat) -> CGPoint {
        // Half the width and height of the cat's flattened picture after it is turned (it only ever turns by quarter turns).
        let across = abs(cos(angle)), along = abs(sin(angle))
        let halfWidth = (across * cat.width + along * cat.height * flatten) / 2
        let halfHeight = (along * cat.width + across * cat.height * flatten) / 2

        let overlap = MinigameLayout.crashOverlap
        let carHalf = CGSize(width: car.size.width / 2, height: car.size.height / 2)

        switch crash.side {
        case .front, .back:
            // At the end of the car it ran into: the right end when the car drives right and it hit the front.
            let end = (crash.side == .front ? 1 : -1) * direction.sign
            return CGPoint(x: car.position.x + end * (carHalf.width + halfWidth - overlap), y: car.position.y)

        case .bottom, .top:
            // Against the side, where it hit, without hanging over the car's ends.
            let limit = max(0, carHalf.width - halfWidth)
            let shift = min(max(crash.offset * cell, -limit), limit)
            let side: CGFloat = crash.side == .top ? 1 : -1
            return CGPoint(x: car.position.x + shift, y: car.position.y + side * (carHalf.height + halfHeight - overlap))
        }
    }

    // MARK: - Camera

    /// Keeps the cat a few rows above the bottom edge and never shows outside the level.
    /// It follows the *drawn* cat, so the camera starts moving smoothly with it.
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
