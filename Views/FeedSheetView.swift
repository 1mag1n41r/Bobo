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
                        Color(red: 0.05, green: 0.12, blue: 0.12),
                        Color(red: 0.16, green: 0.15, blue: 0.09)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    Text("餵食你的鸚鵡")
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

                                    Text("+\(crop.hungerGain) 飽食度  •  +\(crop.happinessGain) 快樂值")
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 0.79, green: 0.86, blue: 0.80))
                                }

                                Spacer()

                                Text("x\(count)")
                                    .font(.headline)
                                    .foregroundStyle(count > 0 ? .white : .white.opacity(0.45))
                            }
                            .padding()
                            .background(
                                count > 0
                                ? Color(red: 0.11, green: 0.24, blue: 0.18).opacity(0.96)
                                : Color(red: 0.11, green: 0.24, blue: 0.18).opacity(0.42)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(count == 0)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("餵食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
}   
