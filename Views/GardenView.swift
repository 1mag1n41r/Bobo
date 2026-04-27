import SwiftUI

struct GardenView: View {
    @EnvironmentObject var store: GameStore
    @State private var selectedTileIndex: Int? = nil
    @State private var showPlantPicker = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.10, blue: 0.08),
                    Color(red: 0.08, green: 0.18, blue: 0.12),
                    Color(red: 0.14, green: 0.12, blue: 0.07)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("菜園")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("為你的鸚鵡種植食物")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        // Inventory summary
                        HStack(spacing: 12) {
                            inventoryBadge(crop: .corn)
                            inventoryBadge(crop: .berry)
                            inventoryBadge(crop: .sunflower)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Garden grid
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(plantingOrigins, id: \.self) { index in
                            let tile = store.garden[index]
                            GardenSlotView(
                                tile: tile,
                                canPlant: store.canPlant(at: index)
                            )
                            .onTapGesture {
                                selectedTileIndex = index
                                if tile.isPlanted() {
                                    if tile.isReady() {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            store.harvest(at: index)
                                        }
                                    }
                                } else if store.canPlant(at: index) {
                                    showPlantPicker = true
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)

                    // Tip
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.89, green: 0.74, blue: 0.40))

                        Text("點擊空地種植，點擊成熟的作物收穫。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
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

    private func inventoryBadge(crop: CropType) -> some View {
        let count = store.inventory.items[crop, default: 0]
        return HStack(spacing: 4) {
            Image(crop.iconAsset)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
            Text("\(count)")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private var plantingOrigins: [Int] {
        stride(from: 0, to: store.rows, by: 3).flatMap { row in
            stride(from: 0, to: store.cols, by: 3).map { col in
                row * store.cols + col
            }
        }
    }
}

// MARK: - Plant Picker

private struct PlantPickerSheet: View {
    let onPick: (CropType) -> Void

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.12, blue: 0.10)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Handle bar
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)

                Text("選擇種子")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                VStack(spacing: 10) {
                    ForEach(CropType.allCases) { crop in
                        Button {
                            onPick(crop)
                        } label: {
                            HStack(spacing: 14) {
                                Image(crop.iconAsset)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(crop.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    Text("生長時間 \(growText(crop.growSeconds))")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("+\(crop.hungerGain)")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color(red: 0.89, green: 0.60, blue: 0.22))
                                    Text("飽食度")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.white.opacity(0.4))
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
    }

    private func growText(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        if mins >= 60 {
            return "\(mins / 60)小時\(mins % 60)分"
        }
        return "\(mins)分鐘"
    }
}

// MARK: - Garden Slot

private struct GardenSlotView: View {
    let tile: GardenTile
    let canPlant: Bool

    var body: some View {
        ZStack {
            // Pixel art tile background
            Image(tile.isPlanted() ? "dirt_tile" : (canPlant ? "grass_tile" : "dirt_tile"))
                .interpolation(.none)
                .resizable()
                .scaledToFill()
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(canPlant || tile.isPlanted() ? 1.0 : 0.3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: borderWidth)
                )

            if let crop = tile.crop, tile.isPlanted() {
                plantedContent(crop: crop)
            } else {
                emptyContent
            }
        }
    }

    private func plantedContent(crop: CropType) -> some View {
        let progress = tile.progress()
        return VStack(spacing: 4) {
            Image(crop.spriteAsset(for: progress))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            if tile.isReady() {
                HStack(spacing: 3) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9))
                    Text("收穫！")
                        .font(.caption2.bold())
                }
                .foregroundStyle(Color(red: 0.38, green: 0.87, blue: 0.55))
            } else {
                progressBar(progress: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var emptyContent: some View {
        VStack(spacing: 6) {
            Image(systemName: canPlant ? "plus" : "lock.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(canPlant ? Color(red: 0.89, green: 0.74, blue: 0.40).opacity(0.7) : .white.opacity(0.15))

            Text(canPlant ? "種植" : "")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [cropAccent.opacity(0.6), cropAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * max(0.02, CGFloat(progress)))
            }
        }
        .frame(width: 60, height: 5)
    }

    private var borderColor: Color {
        if tile.isPlanted() {
            return tile.isReady() ? Color(red: 0.38, green: 0.87, blue: 0.55).opacity(0.5) : Color.white.opacity(0.06)
        }
        return canPlant ? Color(red: 0.89, green: 0.74, blue: 0.40).opacity(0.2) : .clear
    }

    private var borderWidth: CGFloat {
        if tile.isPlanted() && tile.isReady() { return 1.5 }
        return 1
    }

    private var cropAccent: Color {
        guard let crop = tile.crop else { return .white }
        switch crop {
        case .corn: return Color(red: 0.89, green: 0.60, blue: 0.22)
        case .berry: return Color(red: 0.45, green: 0.80, blue: 0.27)
        case .sunflower: return Color(red: 0.89, green: 0.74, blue: 0.40)
        }
    }
}
