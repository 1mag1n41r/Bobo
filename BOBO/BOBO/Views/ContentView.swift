import SwiftUI

struct ContentView: View {
    @StateObject private var store = GameStore()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.12, blue: 0.14),
                    Color(red: 0.09, green: 0.22, blue: 0.19),
                    Color(red: 0.16, green: 0.14, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView {
                PetRoomView()
                    .tabItem {
                        Label("Parrot", systemImage: "bird")
                    }

                GardenView()
                    .tabItem {
                        Label("Garden", systemImage: "leaf")
                    }
            }
            .tint(Color(red: 0.97, green: 0.79, blue: 0.32))
        }
        .environmentObject(store)
    }
}
