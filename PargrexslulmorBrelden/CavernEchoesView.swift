//
//  CavernEchoesView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct CavernEchoesView: View {
    let difficulty: Difficulty
    let level: Int

    @Binding var path: NavigationPath
    @EnvironmentObject private var progress: ProgressStore
    @StateObject private var vm: CavernEchoesViewModel
    @State private var resultPayload: LevelResultPayload?
    @State private var didRecordFinish = false

    init(difficulty: Difficulty, level: Int, path: Binding<NavigationPath>) {
        self.difficulty = difficulty
        self.level = level
        _path = path
        _vm = StateObject(wrappedValue: CavernEchoesViewModel(difficulty: difficulty, level: level))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Listen to the echo pattern, then tap Soft or Bright in the same order. Hard mode adds decoy pulses—ignore them.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)

                    Text("Pattern length: \(vm.pattern.count) steps. Tap Listen, note each Soft vs Bright tone, then repeat.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextPrimary.opacity(0.9))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .adventureRaisedCard(cornerRadius: 18, borderOpacity: 0.32, compact: true)

                wavePanel

                statusRow

                if vm.phase == .ready {
                    Button("Listen to pattern") {
                        vm.beginListening()
                    }
                    .buttonStyle(AdventurePrimaryButtonStyle())
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .foregroundStyle(Color.appBackground)
                    .adventurePrimaryChrome(cornerRadius: 14)
                    .frame(maxWidth: .infinity, minHeight: GameLayout.minTap)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }

                if vm.phase == .playing {
                    Text("Playing…")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appPrimary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.appAccent.opacity(0.35), radius: 8, y: 2)
                }

                if vm.phase == .respond {
                    respondControls
                }

                if difficulty != .easy, let remain = vm.timeRemaining, vm.phase == .respond {
                    let cap = difficulty == .normal ? CavernEchoesViewModel.normalLimitStatic(level: level) : CavernEchoesViewModel.hardLimitStatic(level: level)
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: max(0, cap - remain), total: cap)
                            .tint(Color.appAccent)
                        Text(String(format: "%.0f seconds to answer", max(0, remain)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                    .padding(12)
                    .adventureRaisedCard(cornerRadius: 14, borderOpacity: 0.3, compact: true)
                }
            }
            .padding(.horizontal, GameLayout.horizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AdventureScreenBackground())
        .navigationTitle("Cavern of Echoes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            didRecordFinish = false
            vm.startSession()
        }
        .onChange(of: vm.isComplete) { complete in
            guard complete, !didRecordFinish else { return }
            didRecordFinish = true
            let elapsed = vm.elapsed
            let stars = vm.starsEarned()
            let newIds = progress.recordCompletion(
                activity: .cavern,
                level: level,
                difficulty: difficulty,
                stars: stars,
                elapsed: elapsed
            )
            resultPayload = LevelResultPayload(
                activity: .cavern,
                difficulty: difficulty,
                levelIndex: level,
                stars: stars,
                elapsed: elapsed,
                newlyUnlockedAchievementIds: newIds
            )
        }
        .fullScreenCover(item: $resultPayload) { payload in
            ActivityResultView(
                payload: payload,
                onRetry: {
                    resultPayload = nil
                    didRecordFinish = false
                    vm.resetForRetry()
                },
                onBackToStages: {
                    resultPayload = nil
                    if !path.isEmpty {
                        path.removeLast()
                    }
                },
                onNextStage: {
                    guard level < GameLayout.levelsPerActivity - 1 else { return }
                    let next = AdventureDestination.play(
                        PlayTarget(activity: .cavern, difficulty: difficulty, level: level + 1)
                    )
                    resultPayload = nil
                    DispatchQueue.main.async {
                        if !path.isEmpty {
                            path.removeLast()
                        }
                        path.append(next)
                    }
                }
            )
        }
    }

    private var wavePanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.85),
                            Color.appBackground.opacity(0.42)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.4),
                                    Color.appPrimary.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
            Canvas { context, size in
                let mid = size.height / 2
                for lane in 0 ..< 5 {
                    let y = size.height * (0.22 + CGFloat(lane) * 0.12)
                    var wave = Path()
                    wave.move(to: CGPoint(x: 0, y: y))
                    for s in stride(from: 0, through: size.width, by: 6) {
                        let phase = vm.wavePhase + CGFloat(lane) * 0.4
                        let offset = sin((Double(s) / 40.0) + phase) * 10
                        wave.addLine(to: CGPoint(x: s, y: y + CGFloat(offset)))
                    }
                    context.stroke(wave, with: .color(Color.appAccent.opacity(0.55)), lineWidth: 2)
                }
                if let high = vm.activeToneHigh {
                    let color = high ? Color.appAccent : Color.appPrimary
                    var pulse = Path(ellipseIn: CGRect(x: size.width * 0.42, y: mid - 30, width: size.width * 0.16, height: 60))
                    context.fill(pulse, with: .color(color.opacity(0.45)))
                }
            }
            .padding(12)
        }
        .frame(height: 200)
    }

    private var statusRow: some View {
        HStack {
            Text("Steps entered: \(vm.input.count)/\(vm.pattern.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
            Spacer()
        }
    }

    private var respondControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Soft tone") {
                    vm.registerGuess(high: false)
                }
                .buttonStyle(AdventurePrimaryButtonStyle())
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .foregroundStyle(Color.appTextPrimary)
                .adventureSecondaryChrome(cornerRadius: 14)
                .frame(maxWidth: .infinity, minHeight: GameLayout.minTap)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                Button("Bright tone") {
                    vm.registerGuess(high: true)
                }
                .buttonStyle(AdventurePrimaryButtonStyle())
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .foregroundStyle(Color.appBackground)
                .adventurePrimaryChrome(cornerRadius: 14)
                .frame(maxWidth: .infinity, minHeight: GameLayout.minTap)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
        }
    }
}

extension CavernEchoesViewModel {
    static func normalLimitStatic(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(26, 80 - p * 4.3)
    }

    static func hardLimitStatic(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(22, 66 - p * 3.6)
    }
}
