//
//  AdventureHomeView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct AdventureHomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: AdventureDestination.self) { destination in
                    switch destination {
                    case .hub(let activity):
                        ActivityHubView(activity: activity, path: $path)
                    case .play(let target):
                        playScreen(for: target)
                            .id(target)
                    }
                }
        }
    }

    @ViewBuilder
    private func playScreen(for target: PlayTarget) -> some View {
        switch target.activity {
        case .temple:
            LostTempleView(difficulty: target.difficulty, level: target.level, path: $path)
        case .forest:
            MysticForestView(difficulty: target.difficulty, level: target.level, path: $path)
        case .cavern:
            CavernEchoesView(difficulty: target.difficulty, level: target.level, path: $path)
        }
    }
}
