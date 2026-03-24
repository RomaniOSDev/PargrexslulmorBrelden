//
//  AchievementsView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Achievements")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appTextPrimary, Color.appAccent.opacity(0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.appPrimary.opacity(0.18), radius: 8, y: 4)

                Text("Unlock milestones by exploring every route and refining your skills.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)

                let items = progress.unlockedAchievements
                if items.isEmpty {
                    Text("Play stages to reveal achievements here.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .adventureRaisedCard(cornerRadius: 17, borderOpacity: 0.28, compact: true)
                } else {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.appAccent, Color.appPrimary],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color.appAccent.opacity(0.35), radius: 6, y: 2)
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(Color.appTextPrimary)
                            }
                            Text(item.detail)
                                .font(.subheadline)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .adventureRaisedCard(cornerRadius: 16, compact: true)
                    }
                }
            }
            .padding(.horizontal, GameLayout.horizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AdventureScreenBackground())
        .navigationBarTitleDisplayMode(.inline)
    }
}
