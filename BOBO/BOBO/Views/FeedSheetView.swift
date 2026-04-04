import SwiftUI

struct FeedSheetView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let onFed: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.14, blue: 0.13),
                        Color(red: 0.12, green: 0.21, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    Text("Feed Your Parrot")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    ForEach(CropType.allCases) { crop in
                        let count = store.inventory.items[crop, default: 0]

                        Button {
                            let success = store.feed(crop)
                            if success {
                                onFed()
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(crop.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    Text("+\(crop.hungerGain) Hunger  •  +\(crop.happinessGain) Happiness")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.72))
                                }

                                Spacer()

                                Text("x\(count)")
                                    .font(.headline)
                                    .foregroundStyle(count > 0 ? .white : .white.opacity(0.45))
                            }
                            .padding()
                            .background(Color.white.opacity(count > 0 ? 0.11 : 0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(count == 0)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}   
