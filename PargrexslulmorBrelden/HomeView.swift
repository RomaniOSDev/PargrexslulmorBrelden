//
//  HomeView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore

    private var maxStarsPerActivity: Int {
        GameLayout.levelsPerActivity * 3
    }

    private var totalPossibleStars: Int {
        ActivityKind.allCases.count * maxStarsPerActivity
    }

    private var stagesClearedInRealm: Int {
        ActivityKind.allCases.reduce(0) { partial, activity in
            partial + (0 ..< GameLayout.levelsPerActivity).filter { progress.stars(for: activity, level: $0) > 0 }.count
        }
    }

    private var realmProgress: Double {
        guard totalPossibleStars > 0 else { return 0 }
        return min(1, Double(progress.totalStarsEarned) / Double(totalPossibleStars))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                    .padding(.horizontal, GameLayout.horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 22)

                statsRow
                    .padding(.horizontal, GameLayout.horizontalPadding)
                    .padding(.bottom, 28)

                Text("Expeditions")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appTextPrimary, Color.appAccent.opacity(0.92)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, GameLayout.horizontalPadding)
                    .padding(.bottom, 12)

                VStack(spacing: 16) {
                    ForEach(ActivityKind.allCases, id: \.self) { activity in
                        NavigationLink(value: AdventureDestination.hub(activity)) {
                            HomeExpeditionCard(
                                activity: activity,
                                starsTotal: starsSum(activity),
                                stagesCleared: stagesCleared(activity),
                                stagesUnlocked: stagesUnlockedCount(for: activity),
                                ringProgress: ringFraction(for: activity)
                            )
                        }
                        .buttonStyle(HomeExpeditionButtonStyle())
                    }
                }
                .padding(.horizontal, GameLayout.horizontalPadding)
                .padding(.bottom, 28)
            }
        }
        .scrollIndicators(.hidden)
        .background(AdventureScreenBackground())
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greeting)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                    Text("Chart new routes")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .minimumScaleFactor(0.85)
                        .lineLimit(2)
                }
                Spacer(minLength: 12)
                RealmProgressOrb(progress: realmProgress)
                    .frame(width: 72, height: 72)
            }

            Text("Three realms, \(GameLayout.levelsPerActivity) stages each. Gather stars, unlock achievements, sharpen every skill.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .adventureRaisedCard(cornerRadius: 22, borderOpacity: 0.4)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        case 17 ..< 22: return "Good evening"
        default: return "Welcome back"
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            HomeStatPill(
                icon: "star.fill",
                title: "Stars",
                value: "\(progress.totalStarsEarned)",
                caption: "out of \(totalPossibleStars)"
            )
            HomeStatPill(
                icon: "checkmark.circle.fill",
                title: "Cleared",
                value: "\(stagesClearedInRealm)",
                caption: "stages with stars"
            )
            HomeStatPill(
                icon: "chart.pie.fill",
                title: "Realm",
                value: "\(Int(realmProgress * 100))%",
                caption: "star completion"
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func starsSum(_ activity: ActivityKind) -> Int {
        (0 ..< GameLayout.levelsPerActivity).reduce(0) { $0 + progress.stars(for: activity, level: $1) }
    }

    private func stagesCleared(_ activity: ActivityKind) -> Int {
        (0 ..< GameLayout.levelsPerActivity).filter { progress.stars(for: activity, level: $0) > 0 }.count
    }

    private func ringFraction(for activity: ActivityKind) -> CGFloat {
        guard maxStarsPerActivity > 0 else { return 0 }
        return CGFloat(starsSum(activity)) / CGFloat(maxStarsPerActivity)
    }

    private func stagesUnlockedCount(for activity: ActivityKind) -> Int {
        let idx = activity.rawValue
        guard progress.unlockedLevelIndex.indices.contains(idx) else { return 1 }
        return progress.unlockedLevelIndex[idx] + 1
    }
}

// MARK: - Hero orb

private struct RealmProgressOrb: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appPrimary.opacity(0.35),
                            Color.appSurface.opacity(0.45)
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 42
                    )
                )
            Circle()
                .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)

            Circle()
                .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                .stroke(
                    AngularGradient(
                        colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(6)

            VStack(spacing: 0) {
                Text("\(Int(min(100, progress * 100)))%")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.appTextPrimary)
            }
        }
        .accessibilityLabel("Realm star progress \(Int(progress * 100)) percent")
    }
}

// MARK: - Stat pills

private struct HomeStatPill: View {
    let icon: String
    let title: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appAccent)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(Color.appTextSecondary.opacity(0.9))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .adventureRaisedCard(cornerRadius: 16, borderOpacity: 0.28, compact: true)
    }
}

// MARK: - Expedition card

private struct HomeExpeditionCard: View {
    let activity: ActivityKind
    let starsTotal: Int
    let stagesCleared: Int
    let stagesUnlocked: Int
    let ringProgress: CGFloat

    private var maxStars: Int {
        GameLayout.levelsPerActivity * 3
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.appSurface.opacity(0.9), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: min(1, ringProgress))
                    .stroke(
                        Color.appAccent,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                ExpeditionGlyph(kind: activity)
                    .frame(width: 52, height: 52)
                    .padding(10)
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 8) {
                Text(activity.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.leading)

                Text(activity.subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appBackground.opacity(0.55))
                            .frame(height: 6)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appPrimary, Color.appAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * CGFloat(starsTotal) / CGFloat(max(1, maxStars))), height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Label("\(starsTotal) stars", systemImage: "star.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appAccent)
                    Spacer(minLength: 8)
                    Text("\(stagesCleared)/\(GameLayout.levelsPerActivity) with stars · \(stagesUnlocked) unlocked")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appAccent.opacity(0.85))
        }
        .padding(16)
        .adventureRaisedCard(cornerRadius: 20, borderOpacity: 0.4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.title). \(starsTotal) stars. \(stagesCleared) stages cleared.")
    }
}

private struct HomeExpeditionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(ProgressStore())
    }
}
