import SpriteKit

final class ParrotScene: SKScene {
    private var parrotNode: SKSpriteNode?
    private var idleFrames: [SKTexture] = []
    private var eatFrames: [SKTexture] = []

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill

        if idleFrames.isEmpty || eatFrames.isEmpty {
            loadTextures()
        }

        if parrotNode == nil {
            setupParrot()
        }

        playIdle()
    }

    private func setupParrot() {
        let texture = SKTexture(imageNamed: "parrot_idle_1")
        texture.filteringMode = .nearest

        let node = SKSpriteNode(texture: texture)
        node.setScale(4.0) // 48x48 -> 192x192 display
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(node)
        parrotNode = node
    }

    private func loadTextures() {
        idleFrames = (1...4).map {
            let tex = SKTexture(imageNamed: "parrot_idle_\($0)")
            tex.filteringMode = .nearest
            return tex
        }

        eatFrames = (1...4).map {
            let tex = SKTexture(imageNamed: "parrot_eat_\($0)")
            tex.filteringMode = .nearest
            return tex
        }
    }

    func playIdle() {
        guard let parrotNode, !idleFrames.isEmpty else { return }

        parrotNode.removeAction(forKey: "eat")
        parrotNode.removeAction(forKey: "idle")

        let idle = SKAction.animate(with: idleFrames, timePerFrame: 0.2, resize: false, restore: true)
        let loop = SKAction.repeatForever(idle)
        parrotNode.run(loop, withKey: "idle")
    }

    func playEat() {
        guard let parrotNode, !eatFrames.isEmpty else { return }

        parrotNode.removeAction(forKey: "idle")
        parrotNode.removeAction(forKey: "eat")

        let eat = SKAction.animate(with: eatFrames, timePerFrame: 0.12, resize: false, restore: true)
        let bounceUp = SKAction.moveBy(x: 0, y: 8, duration: 0.08)
        let bounceDown = SKAction.moveBy(x: 0, y: -8, duration: 0.08)
        let bounce = SKAction.sequence([bounceUp, bounceDown])

        let group = SKAction.group([eat, bounce])
        let sequence = SKAction.sequence([
            SKAction.repeat(group, count: 2),
            SKAction.run { [weak self] in
                self?.playIdle()
            }
        ])

        parrotNode.run(sequence, withKey: "eat")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if let parrotNode {
            parrotNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }
}
