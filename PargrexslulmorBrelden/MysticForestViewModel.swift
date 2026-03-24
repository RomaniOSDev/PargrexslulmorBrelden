//
//  MysticForestViewModel.swift
//  PargrexslulmorBrelden
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class MysticForestViewModel: ObservableObject {
    @Published var nodes: [ForestNode]
    @Published var pathOrder: [UUID]
    @Published var currentIndex: Int = 0
    @Published var elapsed: TimeInterval = 0
    @Published var isComplete = false
    @Published var timeRemaining: TimeInterval?
    @Published var wrongTaps: Int = 0

    private var sessionStart = Date()
    private var ticker: AnyCancellable?
    private let difficulty: Difficulty
    private let level: Int

    struct ForestNode: Identifiable, Hashable {
        let id: UUID
        var unitX: CGFloat
        var unitY: CGFloat
        let isDecoy: Bool
    }

    init(difficulty: Difficulty, level: Int) {
        self.difficulty = difficulty
        self.level = level
        let count = Self.nodeCount(difficulty: difficulty, level: level)
        let decoys = Self.decoyCount(difficulty: difficulty)
        let layout = Self.generateLayout(mainCount: count, decoyCount: decoys)
        var built: [ForestNode] = []
        for i in layout.indices {
            let isDecoy = i >= count
            built.append(
                ForestNode(
                    id: UUID(),
                    unitX: layout[i].0,
                    unitY: layout[i].1,
                    isDecoy: isDecoy
                )
            )
        }
        nodes = built
        let mainIds = built.filter { !$0.isDecoy }.map(\.id)
        pathOrder = mainIds.shuffled()
        switch difficulty {
        case .easy:
            timeRemaining = nil
        case .normal:
            timeRemaining = Self.normalLimit(level: level)
        case .hard:
            timeRemaining = Self.hardLimit(level: level)
        }
    }

    /// Spreads points in unit space with minimum separation so taps do not overlap.
    private static func generateLayout(mainCount: Int, decoyCount: Int) -> [(CGFloat, CGFloat)] {
        let total = mainCount + decoyCount
        let minDist: CGFloat = total > 10 ? 0.13 : 0.16
        var points: [(CGFloat, CGFloat)] = []
        var attempts = 0
        while points.count < total, attempts < 800 {
            attempts += 1
            let ux = CGFloat.random(in: 0.12 ... 0.88)
            let uy = CGFloat.random(in: 0.16 ... 0.84)
            let ok = points.allSatisfy { hypot($0.0 - ux, $0.1 - uy) >= minDist }
            if ok {
                points.append((ux, uy))
            }
        }
        while points.count < total {
            let angle = CGFloat(points.count) / CGFloat(max(1, total)) * 2 * .pi
            let r: CGFloat = 0.32
            points.append((0.5 + cos(angle) * r, 0.5 + sin(angle) * r * 0.85))
        }
        return points
    }

    private static func nodeCount(difficulty: Difficulty, level: Int) -> Int {
        let p = GameLayout.levelTier(level)
        switch difficulty {
        case .easy: return min(10, 3 + (p + 2) / 3)
        case .normal: return min(11, 4 + (p + 1) / 2)
        case .hard: return min(12, 5 + p / 2)
        }
    }

    private static func decoyCount(difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy: return 0
        case .normal: return 1
        case .hard: return 3
        }
    }

    private static func normalLimit(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(28, 82 - p * 4.2)
    }

    private static func hardLimit(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(24, 68 - p * 3.5)
    }

    func startSession() {
        sessionStart = Date()
        elapsed = 0
        currentIndex = 0
        wrongTaps = 0
        isComplete = false
        ticker?.cancel()
        ticker = Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed = Date().timeIntervalSince(self.sessionStart)
                guard self.difficulty != .easy, var remain = self.timeRemaining else { return }
                remain -= 0.15
                if remain <= 0 {
                    self.timeRemaining = 0
                    self.timeExpired()
                } else {
                    self.timeRemaining = remain
                }
            }
    }

    private func timeExpired() {
        guard !isComplete else { return }
        wrongTaps += 1
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        rebuildRound(reshufflePathOnly: false)
    }

    /// New positions on harder failures so the map stays fair; easy only reshuffles order.
    private func rebuildRound(reshufflePathOnly: Bool) {
        ticker?.cancel()
        let mainCount = Self.nodeCount(difficulty: difficulty, level: level)
        let decoyTotal = Self.decoyCount(difficulty: difficulty)
        if reshufflePathOnly {
            let mainIds = nodes.filter { !$0.isDecoy }.map(\.id)
            pathOrder = mainIds.shuffled()
        } else {
            let layout = Self.generateLayout(mainCount: mainCount, decoyCount: decoyTotal)
            var newNodes: [ForestNode] = []
            for i in layout.indices {
                let wasDecoy = i >= mainCount
                newNodes.append(ForestNode(id: UUID(), unitX: layout[i].0, unitY: layout[i].1, isDecoy: wasDecoy))
            }
            nodes = newNodes
            pathOrder = newNodes.filter { !$0.isDecoy }.map(\.id).shuffled()
        }
        currentIndex = 0
        sessionStart = Date()
        elapsed = 0
        switch difficulty {
        case .easy:
            timeRemaining = nil
        case .normal:
            timeRemaining = Self.normalLimit(level: level)
        case .hard:
            timeRemaining = Self.hardLimit(level: level)
        }
        isComplete = false
        startSession()
    }

    var currentTargetId: UUID? {
        guard currentIndex < pathOrder.count else { return nil }
        return pathOrder[currentIndex]
    }

    /// Points visited in order (for drawing a trail).
    var visitedTrailPoints: [(CGFloat, CGFloat)] {
        guard currentIndex > 0 else { return [] }
        let ordered = pathOrder.prefix(currentIndex).compactMap { id in nodes.first(where: { $0.id == id }) }
        return ordered.map { ($0.unitX, $0.unitY) }
    }

    func tap(node: ForestNode) {
        guard !isComplete else { return }
        guard let live = nodes.first(where: { $0.id == node.id }) else { return }
        if live.isDecoy {
            wrongTaps += 1
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            if difficulty == .easy {
                currentIndex = 0
            } else {
                rebuildRound(reshufflePathOnly: false)
            }
            return
        }
        guard currentIndex < pathOrder.count else { return }
        if live.id == pathOrder[currentIndex] {
            currentIndex += 1
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if currentIndex >= pathOrder.count {
                ticker?.cancel()
                isComplete = true
            }
        } else {
            wrongTaps += 1
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            if difficulty == .easy {
                currentIndex = 0
            } else {
                rebuildRound(reshufflePathOnly: false)
            }
        }
    }

    func resetAttempt() {
        rebuildRound(reshufflePathOnly: difficulty == .easy)
    }

    /// New layout and path (e.g. after result "Retry").
    func replayFromScratch() {
        rebuildRound(reshufflePathOnly: false)
    }

    func starsEarned() -> Int {
        switch difficulty {
        case .easy:
            if elapsed < 26 { return 3 }
            if elapsed < 48 { return 2 }
            return 1
        case .normal:
            let limit = Self.normalLimit(level: level)
            let ratio = elapsed / limit
            if ratio < 0.42 { return 3 }
            if ratio < 0.7 { return 2 }
            return 1
        case .hard:
            let limit = Self.hardLimit(level: level)
            let ratio = elapsed / limit
            if ratio < 0.38 { return 3 }
            if ratio < 0.66 { return 2 }
            return 1
        }
    }

    deinit {
        ticker?.cancel()
    }
}
