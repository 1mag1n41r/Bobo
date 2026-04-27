import SpriteKit
import UIKit

final class ParrotScene: SKScene {
    private var parrotNode: SKSpriteNode?
    private var toyNode: SKNode?
    private var perchPosition = CGPoint.zero

    // Toy-chase state
    private var isChasingToy = false
    private var toyTargetPosition = CGPoint.zero
    private var lastUpdateTime: TimeInterval = 0

    private let spriteSheet = SKTexture(imageNamed: "ParrotSprite")
    private let spriteSheetSize = CGSize(width: 1264, height: 842)

    // Desired display sizes (computed once scene has valid size)
    private var idleDisplaySize: CGSize = .zero
    private var flyDisplaySize: CGSize = .zero

    // Middle row — idle / standing frames (frames 2-5, skipping first and last)
    private lazy var idleFrames: [SKTexture] = idleFrameRects.compactMap(textureForPixelRect)
    private let idleFrameRects: [CGRect] = [
        CGRect(x: 282, y: 171, width: 147, height: 151),
        CGRect(x: 468, y: 171, width: 143, height: 149),
        CGRect(x: 657, y: 171, width: 137, height: 149),
        CGRect(x: 840, y: 171, width: 143, height: 151)
    ]

    // Eating frames (first and last of row 1)
    private lazy var eatingFrames: [SKTexture] = eatingFrameRects.compactMap(textureForPixelRect)
    private let eatingFrameRects: [CGRect] = [
        CGRect(x: 96, y: 171, width: 148, height: 151),
        CGRect(x: 1022, y: 171, width: 148, height: 151)
    ]

    // Row 3 — wing-flap / flying frames (pixel-measured from actual sprite bounds)
    private lazy var flyingFrames: [SKTexture] = flyingFrameRects.compactMap(textureForPixelRect)
    private let flyingFrameRects: [CGRect] = [
        // Skip frame 0 — start from frame 1
        CGRect(x: 266, y: 575, width: 180, height: 145),
        CGRect(x: 452, y: 575, width: 180, height: 145),
        CGRect(x: 637, y: 575, width: 180, height: 145),
        CGRect(x: 823, y: 575, width: 180, height: 145),
        CGRect(x: 1009, y: 575, width: 180, height: 145)
    ]

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill

        if parrotNode == nil {
            setupParrot()
        }
    }

    // MARK: - Update loop (drives toy-chase)

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime > 0 ? min(currentTime - lastUpdateTime, 0.05) : 0
        lastUpdateTime = currentTime

        guard isChasingToy, let parrotNode else { return }

        let speed: CGFloat = 180
        let dx = toyTargetPosition.x - parrotNode.position.x
        let dy = toyTargetPosition.y - parrotNode.position.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance > 6 {
            // Flip sprite to face direction of travel (xScale is only 1 or -1)
            parrotNode.xScale = dx >= 0 ? 1 : -1

            let step = min(CGFloat(dt) * speed, distance)
            let angle = atan2(dy, dx)
            parrotNode.position.x += cos(angle) * step
            parrotNode.position.y += sin(angle) * step
        }
    }

    // MARK: - Touch handling (move toy to finger)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isChasingToy, let touch = touches.first else { return }
        let location = touch.location(in: self)
        toyTargetPosition = location
        toyNode?.run(SKAction.move(to: location, duration: 0.08))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isChasingToy, let touch = touches.first else { return }
        let location = touch.location(in: self)
        toyTargetPosition = location
        toyNode?.position = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isChasingToy, let touch = touches.first else { return }
        let location = touch.location(in: self)
        toyTargetPosition = location
        toyNode?.run(SKAction.move(to: location, duration: 0.06))
    }

    // MARK: - Public animation triggers

    func playIdle() {
        guard let parrotNode else { return }

        parrotNode.removeAllActions()
        applyIdleAppearance()

        guard !idleFrames.isEmpty else { return }

        let flutter = SKAction.animate(with: idleFrames, timePerFrame: 0.18, resize: false, restore: true)
        let pause = SKAction.wait(forDuration: 0.45)
        let bobUp = SKAction.moveBy(x: 0, y: 2, duration: 0.22)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.moveBy(x: 0, y: -2, duration: 0.22)
        bobDown.timingMode = .easeInEaseOut
        let perchBob = SKAction.sequence([bobUp, bobDown])

        let loop = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.group([flutter, perchBob]),
                pause
            ])
        )

        parrotNode.run(loop, withKey: "idle")
    }

    func playEat() {
        isChasingToy = false
        removeAction(forKey: "toyTimer")
        toyNode?.removeFromParent()
        toyNode = nil

        guard let parrotNode, !eatingFrames.isEmpty else {
            playIdle()
            return
        }

        parrotNode.removeAllActions()
        applyIdleAppearance()

        let eatCycle = SKAction.animate(with: eatingFrames, timePerFrame: 0.2, resize: false, restore: true)
        let eatLoop = SKAction.repeat(eatCycle, count: 4)
        let returnToIdle = SKAction.run { [weak self] in
            self?.playIdle()
        }
        parrotNode.run(SKAction.sequence([eatLoop, returnToIdle]), withKey: "eat")
    }

    func playToy() {
        startToyMode()
    }

    /// Toggle-based toy mode: stays active until explicitly ended
    func startToyMode() {
        guard let parrotNode, !flyingFrames.isEmpty else { return }

        isChasingToy = false
        removeAction(forKey: "toyTimer")
        parrotNode.removeAllActions()
        toyNode?.removeFromParent()

        // Switch to flying size and start flapping
        parrotNode.size = flyDisplaySize
        parrotNode.xScale = 1
        parrotNode.yScale = 1

        let flapLoop = SKAction.repeatForever(
            SKAction.animate(with: flyingFrames, timePerFrame: 0.09, resize: false, restore: true)
        )
        parrotNode.run(flapLoop, withKey: "chase")

        // Fly up to center of screen first, then spawn ball
        let flyUpTarget = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
        let flyUp = SKAction.move(to: flyUpTarget, duration: 0.5)
        flyUp.timingMode = .easeInEaseOut

        let spawnBall = SKAction.run { [weak self] in
            guard let self else { return }
            let toy = self.makeToyNode()
            toy.position = flyUpTarget
            toy.setScale(0)
            self.addChild(toy)
            self.toyNode = toy
            toy.run(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.10),
                SKAction.scale(to: 1.0, duration: 0.08)
            ]))

            self.toyTargetPosition = flyUpTarget
            self.lastUpdateTime = 0
            self.isChasingToy = true
        }

        parrotNode.run(SKAction.sequence([flyUp, spawnBall]))
    }

    func endToyPlay() {
        guard isChasingToy else { return }
        isChasingToy = false
        removeAction(forKey: "toyTimer")

        guard let parrotNode else { return }
        parrotNode.removeAllActions()

        let savedPerch = perchPosition
        let faceRight = SKAction.customAction(withDuration: 0) { [weak parrotNode] _, _ in
            parrotNode?.xScale = 1
        }
        let returnFly = SKAction.group([
            SKAction.move(to: savedPerch, duration: 0.55),
            SKAction.repeat(
                SKAction.animate(with: flyingFrames, timePerFrame: 0.09, resize: false, restore: true),
                count: 4
            )
        ])
        let finish = SKAction.run { [weak self] in
            self?.toyNode?.run(SKAction.sequence([
                SKAction.scale(to: 0, duration: 0.12),
                SKAction.removeFromParent()
            ]))
            self?.toyNode = nil
            self?.parrotNode?.removeAllActions()
            self?.playIdle()
        }

        parrotNode.run(SKAction.sequence([faceRight, returnFly, finish]))
    }

    // MARK: - Layout

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0 else { return }
        computeDisplaySizes()
        let wasInvalid = oldSize.width == 0 || oldSize.height == 0
        if !isChasingToy {
            applyIdleAppearance()
            if wasInvalid { playIdle() }
        }
    }

    private func setupParrot() {
        let texture = standingTexture()
        texture.filteringMode = .nearest

        let node = SKSpriteNode(texture: texture)
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        // Start hidden until scene has valid size
        node.isHidden = true
        addChild(node)
        parrotNode = node
    }

    private func standingTexture() -> SKTexture {
        idleFrames.first ?? textureForPixelRect(CGRect(x: 468, y: 171, width: 143, height: 149)) ?? spriteSheet
    }

    private func computeDisplaySizes() {
        guard size.width > 0, size.height > 0 else { return }

        // Idle size
        if let idleTex = idleFrames.first {
            let ts = idleTex.size()
            if ts.width > 0, ts.height > 0 {
                let scale = min(size.width * 0.18 / ts.width, size.height * 0.18 / ts.height)
                idleDisplaySize = CGSize(width: ts.width * scale, height: ts.height * scale)
            }
        }

        // Flying size
        if let flyTex = flyingFrames.first {
            let ts = flyTex.size()
            if ts.width > 0, ts.height > 0 {
                let scale = min(size.width * 0.22 / ts.width, size.height * 0.22 / ts.height)
                flyDisplaySize = CGSize(width: ts.width * scale, height: ts.height * scale)
            }
        }
    }

    /// Resets parrot to idle texture, size, position, and scale (1)
    private func applyIdleAppearance() {
        guard let parrotNode else { return }
        guard size.width > 0, size.height > 0 else { return }

        let idleTex = standingTexture()
        idleTex.filteringMode = .nearest
        parrotNode.texture = idleTex
        parrotNode.size = idleDisplaySize
        parrotNode.xScale = 1
        parrotNode.yScale = 1
        parrotNode.isHidden = false

        let pos = CGPoint(x: size.width * 0.63, y: size.height * 0.28)
        parrotNode.position = pos
        perchPosition = pos
    }

    // MARK: - Toy node

    private func makeToyNode() -> SKNode {
        let container = SKNode()
        container.name = "toy"

        // Outer glow
        let glow = SKShapeNode(circleOfRadius: 18)
        glow.fillColor = UIColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 0.25)
        glow.strokeColor = .clear
        glow.glowWidth = 6
        container.addChild(glow)

        // Main ball
        let ball = SKShapeNode(circleOfRadius: 10)
        ball.fillColor = UIColor(red: 1.0, green: 0.50, blue: 0.12, alpha: 1)
        ball.strokeColor = UIColor(red: 1.0, green: 0.70, blue: 0.30, alpha: 0.8)
        ball.lineWidth = 2
        container.addChild(ball)

        // Inner highlight
        let highlight = SKShapeNode(circleOfRadius: 4)
        highlight.fillColor = UIColor(red: 1.0, green: 0.80, blue: 0.50, alpha: 0.6)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -2, y: 3)
        container.addChild(highlight)

        // Subtle bounce animation
        let pulseUp = SKAction.scale(to: 1.08, duration: 0.5)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 0.95, duration: 0.5)
        pulseDown.timingMode = .easeInEaseOut
        container.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])))

        return container
    }

    // MARK: - Texture helpers

    private func textureForPixelRect(_ rect: CGRect) -> SKTexture? {
        guard rect.minX >= 0,
              rect.minY >= 0,
              rect.maxX <= spriteSheetSize.width,
              rect.maxY <= spriteSheetSize.height else {
            return nil
        }

        let normalizedRect = CGRect(
            x: rect.minX / spriteSheetSize.width,
            y: (spriteSheetSize.height - rect.maxY) / spriteSheetSize.height,
            width: rect.width / spriteSheetSize.width,
            height: rect.height / spriteSheetSize.height
        )

        let texture = SKTexture(rect: normalizedRect, in: spriteSheet)
        texture.filteringMode = .nearest
        return texture
    }
}
