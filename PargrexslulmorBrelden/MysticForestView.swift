//
//  MysticForestView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct MysticForestView: View {
    let difficulty: Difficulty
    let level: Int

    @Binding var path: NavigationPath
    @EnvironmentObject private var progress: ProgressStore
    @StateObject private var vm: MysticForestViewModel
    @State private var resultPayload: LevelResultPayload?
    @State private var didRecordFinish = false
    @State private var pulse = false

    init(difficulty: Difficulty, level: Int, path: Binding<NavigationPath>) {
        self.difficulty = difficulty
        self.level = level
        _path = path
        _vm = StateObject(wrappedValue: MysticForestViewModel(difficulty: difficulty, level: level))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tap the glowing clearing first, then each next step in order. Red markers are false trails on higher difficulties.")
                    .font(.body)
                    .foregroundStyle(Color.appTextPrimary.opacity(0.92))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .adventureRaisedCard(cornerRadius: 18, borderOpacity: 0.32, compact: true)

                if difficulty != .easy, let remain = vm.timeRemaining {
                    let cap = difficulty == .normal ? MysticForestViewModel.normalLimitStatic(level: level) : MysticForestViewModel.hardLimitStatic(level: level)
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: max(0, cap - remain), total: cap)
                            .tint(Color.appAccent)
                        Text(String(format: "%.0f seconds left", max(0, remain)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                    .padding(12)
                    .adventureRaisedCard(cornerRadius: 14, borderOpacity: 0.3, compact: true)
                }

                HStack {
                    Text("Steps: \(vm.currentIndex) / \(vm.pathOrder.count)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appTextPrimary, Color.appAccent.opacity(0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()
                    Button("New layout") {
                        vm.resetAttempt()
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(Color.appBackground)
                    .adventurePrimaryChrome(cornerRadius: 12)
                    .frame(minHeight: GameLayout.minTap)
                }

                forestCanvas
            }
            .padding(.horizontal, GameLayout.horizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AdventureScreenBackground())
        .navigationTitle("Mystic Forest")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            didRecordFinish = false
            vm.startSession()
            pulse = true
        }
        .onChange(of: vm.isComplete) { complete in
            guard complete, !didRecordFinish else { return }
            didRecordFinish = true
            let elapsed = vm.elapsed
            let stars = vm.starsEarned()
            let newIds = progress.recordCompletion(
                activity: .forest,
                level: level,
                difficulty: difficulty,
                stars: stars,
                elapsed: elapsed
            )
            resultPayload = LevelResultPayload(
                activity: .forest,
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
                    vm.replayFromScratch()
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
                        PlayTarget(activity: .forest, difficulty: difficulty, level: level + 1)
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

    private var forestCanvas: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface.opacity(0.78),
                                Color.appBackground.opacity(0.48)
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
                                        Color.appAccent.opacity(0.38),
                                        Color.appPrimary.opacity(0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 6)

                Canvas { context, size in
                    let trail = vm.visitedTrailPoints
                    if trail.count >= 2 {
                        var path = Path()
                        let p0 = trail[0]
                        path.move(to: CGPoint(x: p0.0 * size.width, y: p0.1 * size.height))
                        for pt in trail.dropFirst() {
                            path.addLine(to: CGPoint(x: pt.0 * size.width, y: pt.1 * size.height))
                        }
                        context.stroke(path, with: .color(Color.appAccent.opacity(0.55)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                }

                ForEach(vm.nodes) { node in
                    let x = node.unitX * w
                    let y = node.unitY * h
                    let active = node.id == vm.currentTargetId
                    Button {
                        vm.tap(node: node)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.appPrimary.opacity(node.isDecoy ? 0.52 : 0.9),
                                            Color.appPrimary.opacity(node.isDecoy ? 0.28 : 0.52)
                                        ],
                                        center: .topLeading,
                                        startRadius: 2,
                                        endRadius: 32
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .scaleEffect(active && pulse ? 1.14 : 1.0)
                                .shadow(
                                    color: active ? Color.appAccent.opacity(0.6) : Color.black.opacity(0.18),
                                    radius: active ? 10 : 5,
                                    x: 0,
                                    y: active ? 3 : 2
                                )
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appPrimary.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.5
                                )
                                .frame(width: 48, height: 48)
                            if node.isDecoy {
                                Text("✕")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.appTextPrimary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: GameLayout.minTap, height: GameLayout.minTap)
                    .position(x: x, y: y)
                    .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: pulse)
                }
            }
        }
        .frame(height: 380)
    }
}

extension MysticForestViewModel {
    static func normalLimitStatic(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(28, 82 - p * 4.2)
    }

    static func hardLimitStatic(level: Int) -> TimeInterval {
        let p = Double(GameLayout.levelTier(level))
        return max(24, 68 - p * 3.5)
    }
}
