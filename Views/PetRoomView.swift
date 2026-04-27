import SwiftUI

struct PetRoomView: View {
    @EnvironmentObject var store: GameStore

    private let parrotBackgroundAssetName = "ParrotForestBackground"

    @State private var playEatAnimation = false
    @State private var toyModeActive = false
    @State private var reactionText: String?

    // Food interaction state
    @State private var showFoodPicker = false
    @State private var selectedFood: CropType?
    @State private var foodDragOffset: CGSize = .zero
    @State private var isDraggingFood = false

    // Stats panel toggle
    @State private var showStatsPanel = false

    var body: some View {
        ZStack {
            // Full-screen background
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                FullScreenBackground(
                    assetName: parrotBackgroundAssetName,
                    cycle: SceneCycle(date: context.date)
                )
            }
            .ignoresSafeArea()

            // Full-screen parrot scene — bird can fly anywhere
            ParrotSpriteView(playEatAnimation: $playEatAnimation, toyModeActive: $toyModeActive)
                .ignoresSafeArea()
                .allowsHitTesting(toyModeActive)

            // Tap anywhere to pat (only when not in toy mode)
            if !toyModeActive {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handlePatInteraction()
                    }
                    .ignoresSafeArea()
            }

            // Reaction text
            if let reactionText {
                VStack {
                    Text(reactionText)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.28))
                        .clipShape(Capsule())
                        .padding(.top, 60)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .allowsHitTesting(false)
            }

            // Mood text at top
            VStack {
                Text(parrotMoodText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    .clipShape(Capsule())
                    .padding(.top, 8)

                Spacer()
            }
            .allowsHitTesting(false)

            // Semi-transparent stats panel
            if showStatsPanel {
                statsPanel
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
            }

            // Bottom interaction overlay (stats toggle + toy + food)
            bottomInteractionOverlay
        }
        .onAppear {
            store.applyOfflineProgress()
        }
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        VStack {
            VStack(spacing: 12) {
                StatBar(title: "飽食度", value: store.pet.hunger, accent: Color(red: 0.89, green: 0.60, blue: 0.22))
                StatBar(title: "快樂值", value: store.pet.happiness, accent: Color(red: 0.45, green: 0.80, blue: 0.27))
                StatBar(title: "體力", value: store.pet.energy, accent: Color(red: 0.17, green: 0.63, blue: 0.49))
            }
            .padding(16)
            .background(Color(red: 0.06, green: 0.14, blue: 0.12).opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .frame(maxWidth: 300)
            .padding(.leading, 20)
            .padding(.top, 50)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom Interaction Overlay

    private var bottomInteractionOverlay: some View {
        VStack {
            Spacer()

            // Food picker or selected food — centered, above the button bar
            if showFoodPicker {
                foodPickerContent
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 12)
            } else if let food = selectedFood {
                draggableFoodView(food: food)
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, 12)
            }

            // Button bar
            HStack {
                // Stats toggle (left)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showStatsPanel.toggle()
                    }
                } label: {
                    circleButton(
                        icon: showStatsPanel ? "chevron.down.circle.fill" : "chart.bar.fill",
                        isActive: showStatsPanel,
                        size: 48
                    )
                }

                Spacer()

                // Toy button
                Button {
                    handleToyInteraction()
                } label: {
                    circleButton(icon: "tennisball.fill", isActive: toyModeActive, size: 52)
                }

                // Food button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if showFoodPicker {
                            // Close picker
                            showFoodPicker = false
                            selectedFood = nil
                            foodDragOffset = .zero
                            isDraggingFood = false
                        } else {
                            // Open picker (keeps selected food visible until new pick)
                            showFoodPicker = true
                            foodDragOffset = .zero
                            isDraggingFood = false
                        }
                    }
                } label: {
                    circleButton(
                        icon: showFoodPicker ? "xmark" : "fork.knife",
                        isActive: showFoodPicker || selectedFood != nil,
                        size: 52
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(.keyboard)
    }

    private func circleButton(icon: String, isActive: Bool, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    isActive
                    ? Color(red: 0.89, green: 0.60, blue: 0.22)
                    : Color(red: 0.10, green: 0.20, blue: 0.16).opacity(0.9)
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isActive ? 0.15 : 0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

            Image(systemName: icon)
                .font(size > 50 ? .title2 : .title3)
                .foregroundStyle(
                    isActive
                    ? Color(red: 0.15, green: 0.10, blue: 0.05)
                    : Color(red: 0.89, green: 0.60, blue: 0.22)
                )
        }
    }

    private var foodPickerContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                ForEach(CropType.allCases) { crop in
                    let count = store.inventory.items[crop, default: 0]

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedFood = crop
                            showFoodPicker = false
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(crop.iconAsset)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)

                            Text(crop.displayName)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text("x\(count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(count > 0 ? Color(red: 0.89, green: 0.60, blue: 0.22) : .white.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .disabled(count == 0)
                    .opacity(count > 0 ? 1.0 : 0.5)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 20, y: -4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private func draggableFoodView(food: CropType) -> some View {
        let feedThreshold: CGFloat = -150

        return HStack(spacing: 14) {
            // Draggable food item
            VStack(spacing: 2) {
                Image(food.iconAsset)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)

                if !isDraggingFood {
                    Text("向上拖曳餵食")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .scaleEffect(isDraggingFood ? 1.1 : 1.0)
            .offset(foodDragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.interactiveSpring()) {
                            isDraggingFood = true
                            foodDragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if value.translation.height < feedThreshold {
                            let success = store.feed(food)
                            if success {
                                playEatAnimation = true
                                showReaction("+\(food.hungerGain) 飽食度")
                                MusicPlayer.shared.playBirdSound()
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                foodDragOffset = .zero
                                isDraggingFood = false
                                // Only dismiss if parrot is full or out of this food
                                let remaining = store.inventory.items[food, default: 0]
                                if store.pet.hunger >= 100 || remaining == 0 {
                                    selectedFood = nil
                                }
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                foodDragOffset = .zero
                                isDraggingFood = false
                            }
                        }
                    }
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isDraggingFood)
        }
    }

    // MARK: - Interactions

    private func handlePatInteraction() {
        if store.patParrot() {
            showReaction("摸摸 +6")
        }
    }

    private func handleToyInteraction() {
        if toyModeActive {
            toyModeActive = false
        } else {
            // Dismiss food UI
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showFoodPicker = false
                selectedFood = nil
                foodDragOffset = .zero
                isDraggingFood = false
            }
            toyModeActive = true
            if store.playWithToy() {
                showReaction("玩耍 +10")
            }
        }
    }

    private func showReaction(_ text: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            reactionText = text
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                if reactionText == text {
                    reactionText = nil
                }
            }
        }
    }

    private var parrotMoodText: String {
        switch store.pet.mood() {
        case .happy:
            return "你的鸚鵡很開心"
        case .neutral:
            return "你的鸚鵡還不錯"
        case .hungry:
            return "你的鸚鵡肚子餓了"
        case .sad:
            return "你的鸚鵡覺得被冷落了"
        case .sleepy:
            return "你的鸚鵡想睡覺了"
        }
    }
}

// MARK: - Full Screen Background

private struct FullScreenBackground: View {
    let assetName: String
    let cycle: SceneCycle

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [cycle.skyTopColor, cycle.skyBottomColor],
                startPoint: .top,
                endPoint: .bottom
            )

            if let image = UIImage(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(cycle.imageShadeTopOpacity),
                                Color.black.opacity(cycle.imageShadeBottomOpacity)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            RadialGradient(
                colors: [
                    cycle.sunGlowColor.opacity(cycle.sunGlowOpacity),
                    Color.clear
                ],
                center: cycle.sunAlignment,
                startRadius: 20,
                endRadius: 300
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(cycle.globalShadeTopOpacity),
                    Color.black.opacity(cycle.globalShadeBottomOpacity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            MovingMist(cycle: cycle)
            NightSparkles(cycle: cycle)
        }
    }
}

// MARK: - Ambient Effects

private struct MovingMist: View {
    let cycle: SceneCycle

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(cycle.mistOpacity),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 280, height: 90)
                .blur(radius: 12)
                .offset(x: cycle.mistOffsetPrimary.width, y: cycle.mistOffsetPrimary.height)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.73, green: 0.90, blue: 1.0).opacity(cycle.mistOpacity * 0.85),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 220, height: 64)
                .blur(radius: 10)
                .offset(x: cycle.mistOffsetSecondary.width, y: cycle.mistOffsetSecondary.height)
        }
        .blendMode(.screen)
    }
}

private struct NightSparkles: View {
    let cycle: SceneCycle

    private let points: [CGPoint] = [
        CGPoint(x: 0.18, y: 0.22),
        CGPoint(x: 0.76, y: 0.18),
        CGPoint(x: 0.70, y: 0.62),
        CGPoint(x: 0.24, y: 0.72),
        CGPoint(x: 0.88, y: 0.40)
    ]

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                Circle()
                    .fill(Color(red: 1.0, green: 0.92, blue: 0.50))
                    .frame(width: 5, height: 5)
                    .blur(radius: 0.6)
                    .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.25).opacity(0.9), radius: 8)
                    .opacity(cycle.sparkleOpacity(for: index))
                    .position(
                        x: geometry.size.width * point.x,
                        y: geometry.size.height * point.y
                    )
            }
        }
    }
}

// MARK: - Scene Cycle

private struct SceneCycle {
    private let progress: Double

    init(date: Date) {
        let cycleDuration: TimeInterval = 90
        progress = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
    }

    private var angle: Double {
        progress * .pi * 2
    }

    private var daylight: Double {
        max(0, sin(angle - .pi / 2) * 0.5 + 0.5)
    }

    private var night: Double {
        1 - daylight
    }

    var skyTopColor: Color {
        blend(
            from: Color(red: 0.04, green: 0.08, blue: 0.16),
            to: Color(red: 0.42, green: 0.71, blue: 0.88),
            amount: daylight
        )
    }

    var skyBottomColor: Color {
        blend(
            from: Color(red: 0.06, green: 0.16, blue: 0.20),
            to: Color(red: 0.82, green: 0.70, blue: 0.44),
            amount: daylight * 0.9
        )
    }

    var imageShadeTopOpacity: Double {
        0.04 + night * 0.10
    }

    var imageShadeBottomOpacity: Double {
        0.10 + night * 0.18
    }

    var globalShadeTopOpacity: Double {
        0.02 + night * 0.08
    }

    var globalShadeBottomOpacity: Double {
        0.12 + night * 0.24
    }

    var sunGlowOpacity: Double {
        0.12 + daylight * 0.34
    }

    var sunGlowColor: Color {
        blend(
            from: Color(red: 0.57, green: 0.68, blue: 0.94),
            to: Color(red: 1.0, green: 0.88, blue: 0.52),
            amount: daylight
        )
    }

    var sunAlignment: UnitPoint {
        UnitPoint(
            x: 0.15 + progress * 0.7,
            y: 0.18 + sin(angle) * 0.08
        )
    }

    var mistOpacity: Double {
        0.04 + daylight * 0.14 + night * 0.05
    }

    var mistOffsetPrimary: CGSize {
        CGSize(
            width: cos(angle * 0.6) * 44,
            height: -60 + sin(angle * 1.1) * 10
        )
    }

    var mistOffsetSecondary: CGSize {
        CGSize(
            width: -50 + sin(angle * 0.8) * 36,
            height: 24 + cos(angle * 1.2) * 14
        )
    }

    func sparkleOpacity(for index: Int) -> Double {
        let flicker = sin(angle * 3 + Double(index) * 1.4) * 0.5 + 0.5
        return night * (0.08 + flicker * 0.5)
    }

    private func blend(from: Color, to: Color, amount: Double) -> Color {
        let clamped = max(0, min(amount, 1))
        let fromComponents = components(for: from)
        let toComponents = components(for: to)

        return Color(
            red: fromComponents.red + (toComponents.red - fromComponents.red) * clamped,
            green: fromComponents.green + (toComponents.green - fromComponents.green) * clamped,
            blue: fromComponents.blue + (toComponents.blue - fromComponents.blue) * clamped
        )
    }

    private func components(for color: Color) -> (red: Double, green: Double, blue: Double) {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red: red, green: green, blue: blue)
        #else
        return (red: 0, green: 0, blue: 0)
        #endif
    }
}

// MARK: - Stat Bar

private struct StatBar: View {
    let title: String
    let value: Int
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()
                Text("\(value)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.76))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accent, accent.opacity(0.65)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * max(0, min(CGFloat(value) / 100, 1)))
                }
            }
            .frame(height: 10)
        }
    }
}
