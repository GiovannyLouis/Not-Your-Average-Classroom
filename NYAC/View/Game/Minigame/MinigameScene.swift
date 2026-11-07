//
//  MinigameScene.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import SpriteKit

/// Pure renderer: every frame it advances the view model, then moves shapes to match it.
final class MinigameScene: SKScene {

    // Smoothing knobs. Higher = snappier, lower = floatier. Both are frame-rate independent.
    private let playerEase: CGFloat = 14           // how fast the drawn chicken closes the gap after a hop
    private let cameraEase: CGFloat = 8            // how fast the camera catches up with the chicken

    private let viewModel: MinigameViewModel
    private let cell = MinigameLayout.cellSize

    private let laneLayer = SKNode()               // row backgrounds
    private let obstacleLayer = SKNode()           // cars and logs
    private let cameraNode = SKCameraNode()
    private let player = SKShapeNode(circleOfRadius: MinigameLayout.cellSize * 0.35)

    private var obstacleNodes: [UUID: SKSpriteNode] = [:]
    private var builtLevel = -1
    private var lastUpdate: TimeInterval = 0

    // The model hops instantly; the drawn chicken trails it by `playerOffset` (in points)
    // and that gap shrinks every frame.
    private var playerOffset = CGPoint.zero
    private var lastRow = 0
    private var lastX: CGFloat = 0

    private let carColors: [SKColor] = [.systemBlue, .systemRed, .systemPurple]
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

        player.fillColor = .white
        player.strokeColor = .clear
        player.zPosition = 2
        addChild(player)

        rebuildLevel()
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

    // MARK: - Level

    private func rebuildLevel() {
        builtLevel = viewModel.levelVersion

        laneLayer.removeAllChildren()
        obstacleLayer.removeAllChildren()
        obstacleNodes.removeAll()

        for (index, row) in viewModel.rows.enumerated() {
            let lane = SKSpriteNode(color: laneColor(for: row.type),
                                    size: CGSize(width: size.width, height: cell))
            lane.position = CGPoint(x: size.width / 2, y: (CGFloat(index) + 0.5) * cell)
            laneLayer.addChild(lane)
        }

        // A new run starts from scratch: no glide from the old spot, camera snaps into place.
        lastRow = viewModel.playerRow
        lastX = viewModel.playerX
        playerOffset = .zero
        player.position = playerBasePosition()
        cameraNode.position = CGPoint(x: size.width / 2, y: cameraTargetY())
    }

    private func laneColor(for type: RowType) -> SKColor {
        switch type {
        case .road:  return SKColor.black
        case .river: return SKColor(red: 0.10, green: 0.40, blue: 0.85, alpha: 1)
        case .safe:  return SKColor(red: 0.22, green: 0.65, blue: 0.28, alpha: 1)
        }
    }

    // MARK: - Syncing shapes with the model

    private func syncObstacles() {
        var alive = Set<UUID>()

        for (index, row) in viewModel.rows.enumerated() where row.type != .safe {
            let y = (CGFloat(index) + 0.5) * cell
            for obstacle in row.obstacles {
                alive.insert(obstacle.id)
                let node = obstacleNodes[obstacle.id] ?? makeNode(for: obstacle, on: row.type)
                node.position = CGPoint(x: obstacle.x * cell, y: y)
            }
        }

        // Remove shapes whose obstacle has left the field.
        for (id, node) in obstacleNodes where !alive.contains(id) {
            node.removeFromParent()
            obstacleNodes[id] = nil
        }
    }

    private func makeNode(for obstacle: Obstacle, on type: RowType) -> SKSpriteNode {
        let color = type == .road ? carColors[obstacle.variant % carColors.count] : logColor
        let node = SKSpriteNode(color: color,
                                size: CGSize(width: obstacle.width * cell, height: cell * 0.7))
        obstacleLayer.addChild(node)
        obstacleNodes[obstacle.id] = node
        return node
    }

    /// Where the chicken really is according to the model.
    private func playerBasePosition() -> CGPoint {
        CGPoint(x: viewModel.playerX * cell,
                y: (CGFloat(viewModel.playerRow) + 0.5) * cell)
    }

    private func syncPlayer(deltaTime dt: TimeInterval) {
        let row = viewModel.playerRow
        let x = viewModel.playerX

        // A hop moves the model by a whole cell in one frame. Instead of teleporting the shape,
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

