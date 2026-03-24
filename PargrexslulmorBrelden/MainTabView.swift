//
//  MainTabView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct MainTabView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            AdventureHomeView()
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                AchievementsView()
            }
            .tabItem {
                Label("Achievements", systemImage: "star.circle")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
        .tint(Color.appAccent)
        .toolbarBackground(
            LinearGradient(
                colors: [
                    Color.appSurface.opacity(0.98),
                    Color.appBackground.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            for: .tabBar
        )
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
