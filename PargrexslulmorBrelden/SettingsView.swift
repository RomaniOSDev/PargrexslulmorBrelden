//
//  SettingsView.swift
//  PargrexslulmorBrelden
//

import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var showConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Settings")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appTextPrimary, Color.appAccent.opacity(0.92)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.appPrimary.opacity(0.2), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 10) {
                    statLine(title: "Total stars collected", value: "\(progress.totalStarsEarned)")
                    statLine(title: "Stages finished", value: "\(progress.completedRuns)")
                    statLine(title: "Time wandering", value: formatDuration(progress.totalPlaySeconds))
                }
                .padding(18)
                .adventureRaisedCard(cornerRadius: 18)

                Text("Support & legal")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)

                VStack(spacing: 0) {
                    settingsLinkRow(title: "Rate us", systemImage: "star.fill") {
                        rateApp()
                    }
                    Divider()
                        .background(Color.appAccent.opacity(0.25))
                    ForEach(Array(AppPolicyLink.allCases.enumerated()), id: \.offset) { idx, link in
                        settingsLinkRow(title: link.settingsLabel, systemImage: "link") {
                            openPolicy(link)
                        }
                        if idx < AppPolicyLink.allCases.count - 1 {
                            Divider()
                                .background(Color.appAccent.opacity(0.25))
                        }
                    }
                }
                .adventureRaisedCard(cornerRadius: 16, compact: true)

                Button("Reset all progress") {
                    showConfirm = true
                }
                .buttonStyle(AdventurePrimaryButtonStyle())
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .foregroundStyle(Color.appBackground)
                .adventurePrimaryChrome(cornerRadius: 14)
                .frame(maxWidth: .infinity, minHeight: GameLayout.minTap)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .confirmationDialog(
                    "Reset all progress?",
                    isPresented: $showConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Reset everything", role: .destructive) {
                        progress.resetAll()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This clears stars, unlocked stages, and statistics.")
                }
            }
            .padding(.horizontal, GameLayout.horizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AdventureScreenBackground())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(Color.appTextPrimary)
                .font(.body.weight(.semibold))
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = max(0, seconds)
        let minutes = Int(s) / 60
        let secs = Int(s) % 60
        return String(format: "%dm %02ds", minutes, secs)
    }

    private func openPolicy(_ link: AppPolicyLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func settingsLinkRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 24)
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
