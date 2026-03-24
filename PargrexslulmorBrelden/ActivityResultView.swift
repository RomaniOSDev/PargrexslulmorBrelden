//
//  ActivityResultView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct ActivityResultView: View {
    let payload: LevelResultPayload
    var onRetry: () -> Void
    var onBackToStages: () -> Void
    var onNextStage: () -> Void

    @State private var showBanner = false
    @State private var visibleStars = 0

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 22) {
                    Text("Stage Complete")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appTextPrimary, Color.appAccent.opacity(0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.appPrimary.opacity(0.2), radius: 10, y: 4)

                    starBlock

                    VStack(alignment: .leading, spacing: 10) {
                        statRow(title: "Time", value: formatTime(payload.elapsed))
                        statRow(title: "Difficulty", value: payload.difficulty.title)
                        statRow(title: "Stars earned", value: "\(payload.stars) / 3")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .adventureRaisedCard(cornerRadius: 18)

                    VStack(spacing: 12) {
                        if hasNext {
                            Button("Next Stage") {
                                onNextStage()
                            }
                            .buttonStyle(AdventurePrimaryButtonStyle())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .foregroundStyle(Color.appBackground)
                            .adventurePrimaryChrome(cornerRadius: 14)
                            .frame(maxWidth: .infinity, minHeight: GameLayout.minTap)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        }

                        Button("Retry") {
                            onRetry()
                        }
                        .buttonStyle(AdventureSecondaryButtonStyle())
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .foregroundStyle(Color.appTextPrimary)
                        .adventureSecondaryChrome(cornerRadius: 14)
                        .frame(maxWidth: .infinity, minHeight: GameLayout.minTap)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                        Button("Back to Stages") {
                            onBackToStages()
                        }
                        .buttonStyle(AdventureSecondaryButtonStyle())
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity, minHeight: GameLayout.minTap)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }
                }
                .padding(.horizontal, GameLayout.horizontalPadding)
                .padding(.vertical, 24)
                .padding(.top, payload.newlyUnlockedAchievementIds.isEmpty ? 0 : 56)
            }
            .background(AdventureScreenBackground())

            if showBanner, let first = payload.newlyUnlockedAchievementIds.first {
                AchievementBanner(achievementId: first)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 12)
                    .padding(.horizontal, GameLayout.horizontalPadding)
            }
        }
        .onAppear {
            animateStars()
            if !payload.newlyUnlockedAchievementIds.isEmpty {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(0.45)) {
                    showBanner = true
                }
            }
        }
    }

    private var hasNext: Bool {
        payload.levelIndex < GameLayout.levelsPerActivity - 1
    }

    private var starBlock: some View {
        HStack(spacing: 18) {
            ForEach(0 ..< 3, id: \.self) { idx in
                resultStar(at: idx)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func resultStar(at idx: Int) -> some View {
        if idx < visibleStars {
            Text("★")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.appAccent.opacity(0.65), radius: 12, y: 3)
                .scaleEffect(1)
                .animation(.spring(response: 0.42, dampingFraction: 0.62), value: visibleStars)
        } else {
            Text("★")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.appTextSecondary.opacity(0.58),
                            Color.appTextSecondary.opacity(0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(0.6)
                .animation(.spring(response: 0.42, dampingFraction: 0.62), value: visibleStars)
        }
    }

    private func animateStars() {
        visibleStars = 0
        let target = min(3, max(0, payload.stars))
        for i in 0 ..< target {
            let delay = Double(i) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                    visibleStars = i + 1
                }
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(Color.appTextPrimary)
                .font(.body.weight(.semibold))
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%.1fs", max(0, t))
    }
}

private struct AchievementBanner: View {
    let achievementId: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.appAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("New achievement")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(titleText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            Spacer()
        }
        .padding(14)
        .adventureRaisedCard(cornerRadius: 16, borderOpacity: 0.42)
    }

    private var titleText: String {
        switch achievementId {
        case "first_spark": return "First Spark unlocked"
        case "steady_trail": return "Steady Trail unlocked"
        case "radiant_run": return "Radiant Run unlocked"
        case "star_gatherer": return "Star Gatherer unlocked"
        case "seasoned_seeker": return "Seasoned Seeker unlocked"
        case "time_wanderer": return "Time Wanderer unlocked"
        case "bold_stride": return "Bold Stride unlocked"
        case "realm_sweep": return "Realm Sweep unlocked"
        default: return "Achievement unlocked"
        }
    }
}
