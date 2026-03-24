//
//  GameModels.swift
//  PargrexslulmorBrelden
//

import Foundation

enum ActivityKind: Int, CaseIterable, Hashable, Codable {
    case temple = 0
    case forest = 1
    case cavern = 2

    var title: String {
        switch self {
        case .temple: return "Lost Temple"
        case .forest: return "Mystic Forest"
        case .cavern: return "Cavern of Echoes"
        }
    }

    var subtitle: String {
        switch self {
        case .temple: return "Solve stone riddles and open hidden ways."
        case .forest: return "Follow trails and fulfill woodland tasks."
        case .cavern: return "Listen closely and move with the echoes."
        }
    }
}

enum Difficulty: String, CaseIterable, Hashable, Codable {
    case easy
    case normal
    case hard

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

struct CompletionRecord: Codable, Hashable {
    let activity: Int
    let level: Int
    let difficulty: String
}

struct PlayTarget: Hashable {
    let activity: ActivityKind
    let difficulty: Difficulty
    let level: Int
}

/// Single navigation type for the Adventure tab so `NavigationLink` and `navigationDestination` share one stack.
enum AdventureDestination: Hashable {
    case hub(ActivityKind)
    case play(PlayTarget)
}

struct LevelResultPayload: Identifiable, Hashable {
    let id: UUID
    let activity: ActivityKind
    let difficulty: Difficulty
    let levelIndex: Int
    let stars: Int
    let elapsed: TimeInterval
    let newlyUnlockedAchievementIds: [String]

    init(
        id: UUID = UUID(),
        activity: ActivityKind,
        difficulty: Difficulty,
        levelIndex: Int,
        stars: Int,
        elapsed: TimeInterval,
        newlyUnlockedAchievementIds: [String]
    ) {
        self.id = id
        self.activity = activity
        self.difficulty = difficulty
        self.levelIndex = levelIndex
        self.stars = stars
        self.elapsed = elapsed
        self.newlyUnlockedAchievementIds = newlyUnlockedAchievementIds
    }
}

struct AchievementItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

enum GameLayout {
    static let horizontalPadding: CGFloat = 16
    static let minTap: CGFloat = 44
    /// Stages per expedition (0 … levelsPerActivity - 1).
    static let levelsPerActivity = 12

    /// Clamped level index for scaling difficulty (0 … last stage).
    static func levelTier(_ level: Int) -> Int {
        min(max(0, level), levelsPerActivity - 1)
    }
}

extension Notification.Name {
    static let progressDidReset = Notification.Name("progressDidReset")
}
