//
//  ActivityHubView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct ActivityHubView: View {
    let activity: ActivityKind
    @Binding var path: NavigationPath
    @EnvironmentObject private var progress: ProgressStore
    @State private var difficulty: Difficulty = .normal

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Difficulty")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appTextPrimary, Color.appAccent.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                HStack(spacing: 10) {
                    ForEach(Difficulty.allCases, id: \.self) { mode in
                        Button {
                            difficulty = mode
                        } label: {
                            Text(mode.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity, minHeight: GameLayout.minTap)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(difficulty == mode ? Color.appBackground : Color.appTextPrimary)
                        .modifier(DifficultyChipChrome(isSelected: difficulty == mode))
                    }
                }

                Text("Stages")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appTextPrimary, Color.appAccent.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top, 6)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0 ..< GameLayout.levelsPerActivity, id: \.self) { level in
                        let unlocked = progress.isLevelUnlocked(activity: activity, level: level)
                        let stars = progress.stars(for: activity, level: level)
                        if unlocked {
                            let target = PlayTarget(activity: activity, difficulty: difficulty, level: level)
                            NavigationLink(value: AdventureDestination.play(target)) {
                                LevelCell(level: level + 1, stars: stars, locked: false)
                            }
                            .buttonStyle(.plain)
                        } else {
                            LevelCell(level: level + 1, stars: stars, locked: true)
                        }
                    }
                }
            }
            .padding(.horizontal, GameLayout.horizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AdventureScreenBackground())
        .navigationTitle(activity.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LevelCell: View {
    let level: Int
    let stars: Int
    let locked: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text("Stage \(level)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(locked ? Color.appTextSecondary : Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if locked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(height: 22)
            } else {
                StarRatingRow(filled: min(3, max(0, stars)))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .adventureRaisedCard(cornerRadius: 16, borderOpacity: locked ? 0.2 : 0.45, compact: true)
        .opacity(locked ? 0.68 : 1)
        .allowsHitTesting(!locked)
    }
}

/// Chip styling for difficulty picker (avoids `AnyShapeStyle` on iOS 16).
private struct DifficultyChipChrome: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return content
            .background(
                Group {
                    if isSelected {
                        shape.fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appPrimary.opacity(0.78)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    } else {
                        shape.fill(
                            LinearGradient(
                                colors: [
                                    Color.appSurface.opacity(0.96),
                                    Color.appSurface.opacity(0.74)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            )
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isSelected ? 0.22 : 0.1),
                            Color.appAccent.opacity(isSelected ? 0.15 : 0.32)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(
                color: isSelected ? Color.appPrimary.opacity(0.32) : Color.black.opacity(0.1),
                radius: isSelected ? 8 : 5,
                x: 0,
                y: isSelected ? 4 : 2
            )
    }
}
