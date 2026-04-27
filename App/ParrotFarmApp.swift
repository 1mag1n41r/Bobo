import SwiftUI
import AVFoundation

@main
struct ParrotFarmApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        MusicPlayer.shared.play()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                MusicPlayer.shared.play()
            case .inactive, .background:
                MusicPlayer.shared.stop()
            @unknown default:
                break
            }
        }
    }
}

final class MusicPlayer {
    static let shared = MusicPlayer()
    private var player: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?

    private init() {
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            if let url = Bundle.main.url(forResource: "Sunlight_Through_the_Canopy", withExtension: "mp3") {
                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.volume = 0.3
            }
        } catch {
            print("Music init failed: \(error)")
        }
    }

    func play() {
        player?.play()
    }

    func stop() {
        player?.stop()
    }

    private var sfxTimer: Timer?

    // Bird sound segments (start, duration) detected from Bobi.m4a
    private let birdSnippets: [(start: TimeInterval, duration: TimeInterval)] = [
        (3.0, 2.5),   // chirps at 3.0–5.5s
        (6.5, 1.5),   // chirps at 6.5–8.0s
        (11.0, 2.0),  // chirps at 11.0–13.0s
        (15.5, 1.5)   // chirps at 15.5–17.0s
    ]

    func playBirdSound() {
        guard let url = Bundle.main.url(forResource: "Bobi", withExtension: "m4a"),
              let snippet = birdSnippets.randomElement() else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.6
            player.currentTime = snippet.start
            player.play()
            sfxPlayer = player

            sfxTimer?.invalidate()
            sfxTimer = Timer.scheduledTimer(withTimeInterval: snippet.duration, repeats: false) { [weak self] _ in
                self?.sfxPlayer?.stop()
            }
        } catch {
            print("SFX failed: \(error)")
        }
    }
}
