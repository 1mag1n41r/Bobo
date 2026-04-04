import SwiftUI

struct PetRoomView: View {
    @EnvironmentObject var store: GameStore

    private let parrotBackgroundAssetName = "ParrotForestBackground"

    @State private var showFeedSheet = false
    @State private var playEatAnimation = false
    @State private var interactionMessage = "Tap the parrot to give it some attention."
    @State private var reactionText: String?
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: PetRoomScrollOffsetKey.self,
                            value: geometry.frame(in: .named("PetRoomScroll")).minY
                        )
                }
                .frame(height: 0)

                VStack(spacing: 18) {
                    heroHeader

                    ZStack(alignment: .bottomLeading) {
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                            SceneBackgroundCard(
                                assetName: parrotBackgroundAssetName,
                                cycle: SceneCycle(date: context.date)
                            )
                        }
                        .frame(height: 390)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Canopy Room")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Text(parrotMoodText)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.88))
                        }
                        .padding(20)

                        VStack {
                            Spacer()

                            ParrotSpriteView(playEatAnimation: $playEatAnimation)
                                .frame(width: 250, height: 250)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handlePatInteraction()
                                }
                                .padding(.bottom, 32)

                            Spacer()
                        }

                        if let reactionText {
                            Text(reactionText)
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.28))
                                .clipShape(Capsule())
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                .padding(.top, 18)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)

                    VStack(spacing: 14) {
                        Text("Scroll for stats and interactions")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))

                        Image(systemName: "chevron.down")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.56))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 80)

                    statsSection
                }
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .coordinateSpace(name: "PetRoomScroll")
            .background(Color.clear)
            .onPreferenceChange(PetRoomScrollOffsetKey.self) { value in
                scrollOffset = value
            }

            CompactStatsOverlay(
                hunger: store.pet.hunger,
                happiness: store.pet.happiness,
                energy: store.pet.energy,
                isVisible: shouldShowPinnedStats
            )
        }
        .sheet(isPresented: $showFeedSheet) {
            FeedSheetView {
                playEatAnimation = true
            }
            .environmentObject(store)
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            store.applyOfflineProgress()
        }
    }

    private var shouldShowPinnedStats: Bool {
        scrollOffset < -180
    }

    private var statsSection: some View {
        VStack(spacing: 18) {
            statusCard

            favoriteFoodCard

            interactionCard

            Button {
                showFeedSheet = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Feed Parrot")
                        .fontWeight(.bold)
                }
                .font(.headline)
                .foregroundStyle(Color(red: 0.16, green: 0.12, blue: 0.06))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.83, blue: 0.34),
                            Color(red: 0.95, green: 0.65, blue: 0.24)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
            }
            .padding(.horizontal)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Parrot")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("A cozy jungle nook for feeding, checking moods, and keeping your bird thriving.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var statusCard: some View {
        VStack(spacing: 14) {
            StatBar(title: "Hunger", value: store.pet.hunger, accent: Color(red: 0.94, green: 0.72, blue: 0.21))
            StatBar(title: "Happiness", value: store.pet.happiness, accent: Color(red: 0.91, green: 0.43, blue: 0.59))
            StatBar(title: "Energy", value: store.pet.energy, accent: Color(red: 0.28, green: 0.77, blue: 0.59))
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var favoriteFoodCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: "carrot.fill")
                    .foregroundStyle(Color(red: 0.98, green: 0.75, blue: 0.30))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Favorite Food")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))

                Text(store.pet.favorite.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var interactionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Interaction")
                .font(.headline)
                .foregroundStyle(.white)

            Text(interactionMessage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.74))

            HStack(spacing: 12) {
                Button {
                    handlePatInteraction()
                } label: {
                    InteractionButtonLabel(
                        icon: "hand.tap.fill",
                        title: "Pat",
                        subtitle: "+Happiness"
                    )
                }

                Button {
                    handleToyInteraction()
                } label: {
                    InteractionButtonLabel(
                        icon: "tennisball.fill",
                        title: "Toy",
                        subtitle: "Play Together"
                    )
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func handlePatInteraction() {
        if store.patParrot() {
            interactionMessage = "Your parrot leans into the pat and seems more content."
            showReaction("Pat +6")
        } else {
            interactionMessage = "Your parrot is already soaking up the affection. Try again in a moment."
        }
    }

    private func handleToyInteraction() {
        if store.playWithToy() {
            playEatAnimation = true
            interactionMessage = "The toy got your parrot moving. Happiness rose, but it spent a little energy."
            showReaction("Play +10")
        } else {
            interactionMessage = "Your parrot needs a short break before playing with the toy again."
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
            return "Your parrot feels happy ✨"
        case .neutral:
            return "Your parrot is doing okay"
        case .hungry:
            return "Your parrot looks hungry"
        case .sad:
            return "Your parrot feels neglected"
        case .sleepy:
            return "Your parrot feels sleepy"
        }
    }
}

private struct CompactStatsOverlay: View {
    let hunger: Int
    let happiness: Int
    let energy: Int
    let isVisible: Bool

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                CompactStatPill(title: "Hun", value: hunger, accent: Color(red: 0.94, green: 0.72, blue: 0.21))
                CompactStatPill(title: "Joy", value: happiness, accent: Color(red: 0.91, green: 0.43, blue: 0.59))
                CompactStatPill(title: "Eng", value: energy, accent: Color(red: 0.28, green: 0.77, blue: 0.59))
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
            .padding(.horizontal)
            .padding(.top, 8)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : -18)
            .animation(.easeInOut(duration: 0.22), value: isVisible)

            Spacer()
        }
        .allowsHitTesting(false)
    }
}

private struct CompactStatPill: View {
    let title: String
    let value: Int
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))

            Text("\(value)")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Capsule()
                .fill(accent.opacity(0.95))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(accent)
                        .frame(width: max(8, CGFloat(value) * 0.7), height: 5)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PetRoomScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct InteractionButtonLabel: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(red: 0.98, green: 0.78, blue: 0.33))

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.66))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct SceneBackgroundCard: View {
    let assetName: String
    let cycle: SceneCycle

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            cycle.skyTopColor,
                            cycle.skyBottomColor
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
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
                endRadius: 260
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
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }
}

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
            .frame(height: 12)
        }
    }
}
