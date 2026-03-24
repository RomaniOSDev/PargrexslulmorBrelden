//
//  RootView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        Group {
            if progress.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}
