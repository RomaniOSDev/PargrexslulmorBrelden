//
//  LostTempleViewModel.swift
//  PargrexslulmorBrelden
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class LostTempleViewModel: ObservableObject {
    @Published var target: [Int]
    @Published var slots: [Int?]
    @Published var bank: [BankPiece]
    @Published var elapsed: TimeInterval = 0
    @Published var isComplete = false
    @Published var timeRemaining: TimeInterval?
    @Published var mistakes: Int = 0
    @Published var livesRemaining: Int

    private var sessionStart = Date()
    private var ticker: AnyCancellable?
    private let difficulty: Difficulty
    private let level: Int

    struct BankPiece: Identifiable, Hashable {
        let id: UUID
        let shape: Int
    }

    init(difficulty: Difficulty, level: Int) {
        self.difficulty = difficulty
        self.level = level
        let count = Self.pieceCount(difficulty: difficulty, level: level)
        let sequence = Self.randomSequence(count: count)
        target = sequence
        slots = Array(repeating: nil, count: count)
        bank = sequence.shuffled().map { BankPiece(id: UUID(), shape: $0) }
        switch difficulty {
        case .easy:
            timeRemaining = nil
            livesRemaining = 99
        case .normal:
            timeRemaining = Self.normalLimit(level: level)
            livesRemaining = 99
        case .hard:
            timeRemaining = Self.hardLimit(level: level)
            livesRemaining = 3
        }
    }

    static func pieceCount(difficulty: Difficulty, level: Int) -> Int {
        let p = GameLayout.levelTier(level)
        switch difficulty {
        case .easy: return min(8, 3 + (p + 1) / 2)
        case .normal: return min(8, 4 + (p + 1) / 2)
        case .hard: return min(9, 5 + p / 2)
        }
    }

    private static func randomSequence(count: Int) -> [Int] {
        (0 ..< count).map { _ in Int.random(in: 0 ..< 4) }
    }

    static func normalLimit(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(26, 78 - p * 4.5)
    }

    static func hardLimit(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(20, 62 - p * 3.8)
    }

    func startSession() {
        sessionStart = Date()
        elapsed = 0
        mistakes = 0
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
        mistakes += 1
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        if difficulty == .hard {
            livesRemaining = max(0, livesRemaining - 1)
            if livesRemaining <= 0 {
                livesRemaining = 3
            }
        }
        regeneratePuzzleKeepingSize()
    }

    func manualReset() {
        regeneratePuzzleKeepingSize()
    }

    private func regeneratePuzzleKeepingSize() {
        ticker?.cancel()
        let count = target.count
        let sequence = Self.randomSequence(count: count)
        target = sequence
        slots = Array(repeating: nil, count: count)
        bank = sequence.shuffled().map { BankPiece(id: UUID(), shape: $0) }
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

    func placeFromBank(bankIndex: Int, slotIndex: Int) {
        guard !isComplete, bank.indices.contains(bankIndex),
              slots.indices.contains(slotIndex),
              slots[slotIndex] == nil else { return }
        var nextBank = bank
        let piece = nextBank.remove(at: bankIndex).shape
        var nextSlots = slots
        nextSlots[slotIndex] = piece
        bank = nextBank
        slots = nextSlots
        if bank.isEmpty {
            verifyCompletion()
        }
    }

    func returnToBank(slotIndex: Int) {
        guard !isComplete, slots.indices.contains(slotIndex), let value = slots[slotIndex] else { return }
        var nextSlots = slots
        nextSlots[slotIndex] = nil
        var nextBank = bank
        nextBank.append(BankPiece(id: UUID(), shape: value))
        slots = nextSlots
        bank = nextBank
    }

    func dragBankPieceToSlot(bankIndex: Int, slotIndex: Int) {
        placeFromBank(bankIndex: bankIndex, slotIndex: slotIndex)
    }

    private func verifyCompletion() {
        guard slots.count == target.count else { return }
        for i in slots.indices {
            guard let s = slots[i], s == target[i] else {
                mismatch()
                return
            }
        }
        ticker?.cancel()
        isComplete = true
    }

    private func mismatch() {
        mistakes += 1
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        if difficulty == .hard {
            livesRemaining = max(0, livesRemaining - 1)
            if livesRemaining <= 0 {
                livesRemaining = 3
            }
        }
        regeneratePuzzleKeepingSize()
    }

    func starsEarned() -> Int {
        switch difficulty {
        case .easy:
            if elapsed < 24 { return 3 }
            if elapsed < 46 { return 2 }
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
            if ratio < 0.66 { return 2 }
            return 1
        }
    }

    deinit {
        ticker?.cancel()
    }
}
