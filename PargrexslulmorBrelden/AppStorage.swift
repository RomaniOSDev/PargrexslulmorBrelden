//
//  AppStorage.swift
//  PargrexslulmorBrelden
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ProgressStore: ObservableObject {
    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let stars = "starsGrid"
        static let unlocked = "unlockedLevels"
        static let totalPlaySeconds = "totalPlaySeconds"
        static let completedRuns = "completedRuns"
        static let completions = "completionRecords"
    }

    private let defaults = UserDefaults.standard

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published private(set) var starsGrid: [[Int]]
    @Published private(set) var unlockedLevelIndex: [Int]
    @Published private(set) var totalPlaySeconds: Double
    @Published private(set) var completedRuns: Int
    @Published private(set) var completionRecords: [CompletionRecord]

    init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        if let data = defaults.data(forKey: Keys.stars),
           let decoded = try? JSONDecoder().decode([[Int]].self, from: data),
           decoded.count == ActivityKind.allCases.count
        {
            let targetLen = GameLayout.levelsPerActivity
            var normalizedStars = false
            let mappedGrid: [[Int]] = decoded.map { row in
                if row.count == targetLen { return row }
                normalizedStars = true
                if row.count < targetLen { return row + Array(repeating: 0, count: targetLen - row.count) }
                return Array(row.prefix(targetLen))
            }
            if normalizedStars {
                if let encoded = try? JSONEncoder().encode(mappedGrid) {
                    defaults.set(encoded, forKey: Keys.stars)
                }
            }
            starsGrid = mappedGrid
        } else {
            starsGrid = ActivityKind.allCases.map { _ in Array(repeating: 0, count: GameLayout.levelsPerActivity) }
        }
        if let data = defaults.data(forKey: Keys.unlocked),
           let decoded = try? JSONDecoder().decode([Int].self, from: data),
           decoded.count == ActivityKind.allCases.count
        {
            unlockedLevelIndex = decoded
        } else {
            unlockedLevelIndex = ActivityKind.allCases.map { _ in 0 }
        }
        totalPlaySeconds = defaults.double(forKey: Keys.totalPlaySeconds)
        completedRuns = defaults.integer(forKey: Keys.completedRuns)
        if let data = defaults.data(forKey: Keys.completions),
           let decoded = try? JSONDecoder().decode([CompletionRecord].self, from: data)
        {
            completionRecords = decoded
        } else {
            completionRecords = []
        }
    }

    var totalStarsEarned: Int {
        starsGrid.flatMap(\.self).reduce(0, +)
    }

    func stars(for activity: ActivityKind, level: Int) -> Int {
        guard starsGrid.indices.contains(activity.rawValue),
              starsGrid[activity.rawValue].indices.contains(level) else { return 0 }
        return starsGrid[activity.rawValue][level]
    }

    func isLevelUnlocked(activity: ActivityKind, level: Int) -> Bool {
        level <= unlockedLevelIndex[activity.rawValue]
    }

    func recordCompletion(
        activity: ActivityKind,
        level: Int,
        difficulty: Difficulty,
        stars: Int,
        elapsed: TimeInterval
    ) -> [String] {
        let prevAchievementIds = Set(unlockedAchievements.map(\.id))

        var nextStars = starsGrid
        let best = max(nextStars[activity.rawValue][level], stars)
        nextStars[activity.rawValue][level] = best
        starsGrid = nextStars

        let maxIdx = GameLayout.levelsPerActivity - 1
        var nextUnlocked = unlockedLevelIndex
        if level == nextUnlocked[activity.rawValue], level < maxIdx {
            nextUnlocked[activity.rawValue] = level + 1
            unlockedLevelIndex = nextUnlocked
        }

        totalPlaySeconds += elapsed
        completedRuns += 1
        var nextCompletions = completionRecords
        nextCompletions.append(
            CompletionRecord(activity: activity.rawValue, level: level, difficulty: difficulty.rawValue)
        )
        completionRecords = nextCompletions

        persist()

        let newIds = unlockedAchievements.map(\.id).filter { !prevAchievementIds.contains($0) }
        return newIds
    }

    func persist() {
        defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding)
        if let data = try? JSONEncoder().encode(starsGrid) {
            defaults.set(data, forKey: Keys.stars)
        }
        if let data = try? JSONEncoder().encode(unlockedLevelIndex) {
            defaults.set(data, forKey: Keys.unlocked)
        }
        defaults.set(totalPlaySeconds, forKey: Keys.totalPlaySeconds)
        defaults.set(completedRuns, forKey: Keys.completedRuns)
        if let data = try? JSONEncoder().encode(completionRecords) {
            defaults.set(data, forKey: Keys.completions)
        }
        objectWillChange.send()
    }

    func finishOnboarding() {
        hasSeenOnboarding = true
        persist()
    }

    func resetAll() {
        hasSeenOnboarding = false
        starsGrid = ActivityKind.allCases.map { _ in Array(repeating: 0, count: GameLayout.levelsPerActivity) }
        unlockedLevelIndex = ActivityKind.allCases.map { _ in 0 }
        totalPlaySeconds = 0
        completedRuns = 0
        completionRecords = []
        defaults.removeObject(forKey: Keys.hasSeenOnboarding)
        defaults.removeObject(forKey: Keys.stars)
        defaults.removeObject(forKey: Keys.unlocked)
        defaults.removeObject(forKey: Keys.totalPlaySeconds)
        defaults.removeObject(forKey: Keys.completedRuns)
        defaults.removeObject(forKey: Keys.completions)
        NotificationCenter.default.post(name: .progressDidReset, object: nil)
        objectWillChange.send()
    }

    var unlockedAchievements: [AchievementItem] {
        var items: [AchievementItem] = []

        if totalStarsEarned >= 1 {
            items.append(
                AchievementItem(
                    id: "first_spark",
                    title: "First Spark",
                    detail: "Earn your first star."
                )
            )
        }

        if completedRuns >= 3 {
            items.append(
                AchievementItem(
                    id: "steady_trail",
                    title: "Steady Trail",
                    detail: "Finish three stages."
                )
            )
        }

        if starsGrid.flatMap(\.self).contains(3) {
            items.append(
                AchievementItem(
                    id: "radiant_run",
                    title: "Radiant Run",
                    detail: "Earn a perfect score on any stage."
                )
            )
        }

        if totalStarsEarned >= 20 {
            items.append(
                AchievementItem(
                    id: "star_gatherer",
                    title: "Star Gatherer",
                    detail: "Collect twenty stars overall."
                )
            )
        }

        if completedRuns >= 10 {
            items.append(
                AchievementItem(
                    id: "seasoned_seeker",
                    title: "Seasoned Seeker",
                    detail: "Complete ten stages."
                )
            )
        }

        if totalPlaySeconds >= 300 {
            items.append(
                AchievementItem(
                    id: "time_wanderer",
                    title: "Time Wanderer",
                    detail: "Spend five minutes adventuring."
                )
            )
        }

        if completionRecords.contains(where: { $0.difficulty == Difficulty.hard.rawValue }) {
            items.append(
                AchievementItem(
                    id: "bold_stride",
                    title: "Bold Stride",
                    detail: "Clear a stage on Hard difficulty."
                )
            )
        }

        if ActivityKind.allCases.allSatisfy({ act in
            (0 ..< GameLayout.levelsPerActivity).allSatisfy { stars(for: act, level: $0) > 0 }
        }) {
            items.append(
                AchievementItem(
                    id: "realm_sweep",
                    title: "Realm Sweep",
                    detail: "Earn at least one star on every stage."
                )
            )
        }

        return items
    }
}
