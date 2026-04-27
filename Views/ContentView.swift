import SwiftUI

struct ContentView: View {
    @StateObject private var store = GameStore()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.10, blue: 0.12),
                    Color(red: 0.08, green: 0.21, blue: 0.18),
                    Color(red: 0.20, green: 0.15, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView {
                PetRoomView()
                    .tabItem {
                        Label("鸚鵡", systemImage: "bird")
                    }

                GardenView()
                    .tabItem {
                        Label("菜園", systemImage: "leaf")
                    }
            }
            .tint(Color(red: 0.90, green: 0.59, blue: 0.21))
        }
        .environmentObject(store)
    }
}
