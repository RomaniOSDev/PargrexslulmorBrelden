//
//  CavernEchoesViewModel.swift
//  PargrexslulmorBrelden
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class CavernEchoesViewModel: ObservableObject {
    enum Phase: Equatable {
        case ready
        case playing
        case respond
        case finished
    }

    @Published private(set) var pattern: [Bool]
    @Published private(set) var phase: Phase = .ready
    @Published var input: [Bool] = []
    @Published var elapsed: TimeInterval = 0
    @Published var isComplete = false
    @Published var timeRemaining: TimeInterval?
    @Published var wavePhase: CGFloat = 0
    @Published var activeToneHigh: Bool?

    private var sessionStart = Date()
    private var ticker: AnyCancellable?
    private var waveTicker: AnyCancellable?
    private let difficulty: Difficulty
    private let level: Int
    private let tonePlayer = CavernTonePlayer()

    init(difficulty: Difficulty, level: Int) {
        self.difficulty = difficulty
        self.level = level
        let length = Self.patternLength(difficulty: difficulty, level: level)
        pattern = (0 ..< length).map { _ in Bool.random() }
        switch difficulty {
        case .easy:
            timeRemaining = nil
        case .normal:
            timeRemaining = Self.normalLimit(level: level)
        case .hard:
            timeRemaining = Self.hardLimit(level: level)
        }
    }

    private static func patternLength(difficulty: Difficulty, level: Int) -> Int {
        let p = GameLayout.levelTier(level)
        switch difficulty {
        case .easy: return min(12, 3 + (p + 1) / 2)
        case .normal: return min(14, 4 + p / 2)
        case .hard: return min(16, 5 + (p + 1) / 2)
        }
    }

    private static func normalLimit(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(26, 80 - p * 4.3)
    }

    private static func hardLimit(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(22, 66 - p * 3.6)
    }

    func resetForRetry() {
        let length = Self.patternLength(difficulty: difficulty, level: level)
        pattern = (0 ..< length).map { _ in Bool.random() }
        switch difficulty {
        case .easy:
            timeRemaining = nil
        case .normal:
            timeRemaining = Self.normalLimit(level: level)
        case .hard:
            timeRemaining = Self.hardLimit(level: level)
        }
        startSession()
    }

    func startSession() {
        sessionStart = Date()
        elapsed = 0
        input = []
        isComplete = false
        phase = .ready
        activeToneHigh = nil
        ticker?.cancel()
        waveTicker?.cancel()
        waveTicker = Timer.publish(every: 0.06, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.wavePhase += 0.08
            }
    }

    func beginListening() {
        guard phase == .ready else { return }
        Task { await playPattern() }
    }

    private func playPattern() async {
        phase = .playing
        tonePlayer.configureIfNeeded()
        var index = 0
        while index < pattern.count {
            let tone = pattern[index]
            activeToneHigh = tone
            tonePlayer.play(high: tone)
            UIImpactFeedbackGenerator(style: tone ? .light : .medium).impactOccurred()
            try? await Task.sleep(nanoseconds: 520_000_000)
            activeToneHigh = nil
            index += 1
            if difficulty == .hard, Bool.random() {
                let decoy = Bool.random()
                tonePlayer.play(high: decoy)
                try? await Task.sleep(nanoseconds: 220_000_000)
            }
            try? await Task.sleep(nanoseconds: 160_000_000)
        }
        phase = .respond
        input = []
        sessionStart = Date()
        startRespondTimerIfNeeded()
    }

    private func startRespondTimerIfNeeded() {
        ticker?.cancel()
        guard difficulty != .easy else {
            ticker = Timer.publish(every: 0.12, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    self.elapsed = Date().timeIntervalSince(self.sessionStart)
                }
            return
        }
        switch difficulty {
        case .easy:
            break
        case .normal:
            timeRemaining = Self.normalLimit(level: level)
        case .hard:
            timeRemaining = Self.hardLimit(level: level)
        }
        ticker = Timer.publish(every: 0.12, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed = Date().timeIntervalSince(self.sessionStart)
                guard var remain = self.timeRemaining else { return }
                remain -= 0.12
                if remain <= 0 {
                    self.failRound()
                } else {
                    self.timeRemaining = remain
                }
            }
    }

    func registerGuess(high: Bool) {
        guard phase == .respond else { return }
        var next = input
        next.append(high)
        input = next
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        let idx = next.count - 1
        guard idx < pattern.count else { return }
        if next[idx] != pattern[idx] {
            failRound()
            return
        }
        if next.count == pattern.count {
            ticker?.cancel()
            phase = .finished
            isComplete = true
        }
    }

    private func failRound() {
        ticker?.cancel()
        input = []
        phase = .ready
        pattern = (0 ..< Self.patternLength(difficulty: difficulty, level: level)).map { _ in Bool.random() }
        switch difficulty {
        case .easy:
            timeRemaining = nil
        case .normal:
            timeRemaining = Self.normalLimit(level: level)
        case .hard:
            timeRemaining = Self.hardLimit(level: level)
        }
        sessionStart = Date()
        elapsed = 0
        isComplete = false
        startSession()
    }

    func starsEarned() -> Int {
        switch difficulty {
        case .easy:
            if elapsed < 18 { return 3 }
            if elapsed < 34 { return 2 }
            return 1
        case .normal:
            let limit = Self.normalLimit(level: level)
            let ratio = elapsed / limit
            if ratio < 0.4 { return 3 }
            if ratio < 0.68 { return 2 }
            return 1
        case .hard:
            let limit = Self.hardLimit(level: level)
            let ratio = elapsed / limit
            if ratio < 0.36 { return 3 }
            if ratio < 0.64 { return 2 }
            return 1
        }
    }

    deinit {
        ticker?.cancel()
        waveTicker?.cancel()
    }
}
