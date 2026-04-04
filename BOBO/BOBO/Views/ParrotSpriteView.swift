import SwiftUI
import SpriteKit

struct ParrotSpriteView: UIViewRepresentable {
    @Binding var playEatAnimation: Bool

    private let scene = ParrotScene()

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        scene.size = uiView.bounds.size

        if playEatAnimation {
            scene.playEat()

            DispatchQueue.main.async {
                playEatAnimation = false
            }
        }
    }
}
