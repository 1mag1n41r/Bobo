import SwiftUI
import SpriteKit

struct ParrotSpriteView: UIViewRepresentable {
    @Binding var playEatAnimation: Bool
    @Binding var toyModeActive: Bool

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.isUserInteractionEnabled = true
        view.presentScene(context.coordinator.scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        let scene = context.coordinator.scene
        let newSize = uiView.bounds.size
        if newSize.width > 0 && newSize.height > 0 {
            let wasZero = scene.size.width == 0 || scene.size.height == 0
            scene.size = newSize
            if wasZero {
                scene.playIdle()
            }
        }

        if playEatAnimation {
            scene.playEat()
            DispatchQueue.main.async { playEatAnimation = false }
        }

        // Toggle toy mode on/off
        if toyModeActive != context.coordinator.lastToyMode {
            context.coordinator.lastToyMode = toyModeActive
            if toyModeActive {
                scene.startToyMode()
            } else {
                scene.endToyPlay()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        let scene = ParrotScene()
        var lastToyMode = false
    }
}
