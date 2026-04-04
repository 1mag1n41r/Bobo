import SwiftUI

struct GardenView: View {
    @EnvironmentObject var store: GameStore
    @State private var selectedTileIndex: Int? = nil
    @State private var showPlantPicker = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Garden")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Plant on highlighted starts. Each seed grows into a 3×3 crop patch.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
                .padding(.horizontal)

                VStack(spacing: 14) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(plantingOrigins, id: \.self) { index in
                            let tile = store.garden[index]
                            GardenSlotView(
                                tile: tile,
                                canPlant: store.canPlant(at: index)
                            )
                            .onTapGesture {
                                selectedTileIndex = index
                                if tile.isPlanted() {
                                    store.harvest(at: index)
                                } else if store.canPlant(at: index) {
                                    showPlantPicker = true
                                }
                            }
                        }
                    }

                    Text("Each square is one planting slot. Plant up to nine crop patches and tap a grown patch to harvest.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color.clear)
        .sheet(isPresented: $showPlantPicker) {
            PlantPickerSheet { crop in
                if let idx = selectedTileIndex {
                    store.plant(at: idx, crop: crop)
                }
                showPlantPicker = false
            }
            .presentationDetents([.medium])
        }
    }

    private var plantingOrigins: [Int] {
        stride(from: 0, to: store.rows, by: 3).flatMap { row in
            stride(from: 0, to: store.cols, by: 3).map { col in
                row * store.cols + col
            }
        }
    }
}

private struct PlantPickerSheet: View {
    let onPick: (CropType) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.18, blue: 0.12),
                    Color(red: 0.17, green: 0.13, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Plant Food")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                ForEach(CropType.allCases) { crop in
                    Button {
                        onPick(crop)
                    } label: {
                        HStack {
                            Text(crop.displayName)
                                .foregroundStyle(.white)
                            Spacer()
                            Text(growText(crop.growSeconds))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .padding()
                        .background(Color.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    private func growText(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        return "\(mins) min"
    }
}

private struct GardenSlotView: View {
    let tile: GardenTile
    let canPlant: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(backgroundStyle)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderColor, lineWidth: canPlant && !tile.isPlanted() ? 1.6 : 1)
                )
                .frame(height: 108)

            if let crop = tile.crop, tile.isPlanted() {
                VStack(spacing: 8) {
                    Image(systemName: cropIcon(crop))
                        .font(.title2)
                        .foregroundStyle(cropColor(crop))

                    Text(cropLabel(crop))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)

                    if tile.isReady() {
                        Text("Ready to Harvest")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.38, green: 0.87, blue: 0.60))
                    } else {
                        Text(progressLabel(tile.progress()))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: canPlant ? "plus.circle.fill" : "leaf")
                        .font(.title2)
                        .foregroundStyle(canPlant ? Color(red: 0.89, green: 0.74, blue: 0.40) : .white.opacity(0.22))

                    Text(canPlant ? "Empty Plot" : "Unavailable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(canPlant ? .white.opacity(0.85) : .white.opacity(0.42))
                }
            }
        }
    }

    private var backgroundStyle: Color {
        if let crop = tile.crop, tile.isPlanted() {
            return cropColor(crop).opacity(tile.isReady() ? 0.35 : 0.18)
        }

        return canPlant ? Color(red: 0.54, green: 0.38, blue: 0.19).opacity(0.38) : Color.white.opacity(0.05)
    }

    private var borderColor: Color {
        if tile.isPlanted() {
            return tile.isReady() ? Color(red: 0.38, green: 0.87, blue: 0.60) : Color.white.opacity(0.16)
        }

        return canPlant ? Color(red: 0.89, green: 0.74, blue: 0.40).opacity(0.6) : .clear
    }

    private func cropColor(_ crop: CropType) -> Color {
        switch crop {
        case .corn:
            return Color(red: 0.96, green: 0.84, blue: 0.27)
        case .berry:
            return Color(red: 0.91, green: 0.43, blue: 0.66)
        case .sunflower:
            return Color(red: 0.96, green: 0.64, blue: 0.26)
        }
    }

    private func cropLabel(_ crop: CropType) -> String {
        switch crop {
        case .corn:
            return "Corn"
        case .berry:
            return "Berry"
        case .sunflower:
            return "Sun"
        }
    }

    private func cropIcon(_ crop: CropType) -> String {
        switch crop {
        case .corn:
            return "ear.fill"
        case .berry:
            return "circle.hexagongrid.fill"
        case .sunflower:
            return "sun.max.fill"
        }
    }

    private func progressLabel(_ progress: Double) -> String {
        "\(Int(progress * 100))%"
    }
}
