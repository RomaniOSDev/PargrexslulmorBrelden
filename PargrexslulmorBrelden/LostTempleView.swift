//
//  LostTempleView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct LostTempleView: View {
    let difficulty: Difficulty
    let level: Int

    @Binding var path: NavigationPath
    @EnvironmentObject private var progress: ProgressStore
    @StateObject private var vm: LostTempleViewModel
    @State private var resultPayload: LevelResultPayload?
    @State private var selectedBankIndex: Int?
    @State private var didRecordFinish = false

    init(difficulty: Difficulty, level: Int, path: Binding<NavigationPath>) {
        self.difficulty = difficulty
        self.level = level
        _path = path
        _vm = StateObject(wrappedValue: LostTempleViewModel(difficulty: difficulty, level: level))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                boardSection
                controls
            }
            .padding(.horizontal, GameLayout.horizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AdventureScreenBackground())
        .navigationTitle("Lost Temple")
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
                activity: .temple,
                level: level,
                difficulty: difficulty,
                stars: stars,
                elapsed: elapsed
            )
            resultPayload = LevelResultPayload(
                activity: .temple,
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
                    selectedBankIndex = nil
                    vm.manualReset()
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
                        PlayTarget(activity: .temple, difficulty: difficulty, level: level + 1)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Match your row to the reference. Tap a carved piece to select it, then tap an empty slot to place it. Tap a filled slot to return its piece.")
                .font(.body)
                .foregroundStyle(Color.appTextPrimary.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if difficulty != .easy, let remain = vm.timeRemaining {
                let cap = difficulty == .normal ? LostTempleViewModel.normalLimit(level: level) : LostTempleViewModel.hardLimit(level: level)
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: min(cap, max(0, remain)), total: cap)
                        .tint(Color.appAccent)
                    Text(String(format: "%.0f seconds left", max(0, remain)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                }
            }
            if difficulty == .hard {
                Text("Lives: \(vm.livesRemaining)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }
        }
        .padding(16)
        .adventureRaisedCard(cornerRadius: 18, borderOpacity: 0.34, compact: true)
    }

    /// One width for slots and bank so drag math matches the reference row.
    private var boardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            referenceRow
            GeometryReader { geo in
                let boardWidth = geo.size.width
                let count = max(vm.slots.count, 1)
                let slotSpacing: CGFloat = 8
                let slotW = (boardWidth - CGFloat(count - 1) * slotSpacing) / CGFloat(count)

                VStack(alignment: .leading, spacing: 14) {
                    slotsRowInner(slotW: slotW, slotCount: count, boardWidth: boardWidth, slotSpacing: slotSpacing)
                    bankRowInner(boardWidth: boardWidth, slotSpacing: slotSpacing)
                }
            }
            .frame(height: 220)
        }
    }

    private var referenceRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reference")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            HStack(spacing: 10) {
                ForEach(Array(vm.target.enumerated()), id: \.offset) { _, shape in
                    GlyphShapeView(shape: shape)
                        .frame(width: 46, height: 46)
                        .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 3)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appSurface.opacity(0.95),
                                            Color.appSurface.opacity(0.65)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1)
                        )
                }
            }
            .padding(12)
            .adventureInsetWell(cornerRadius: 16)
        }
    }

    private func slotsRowInner(slotW: CGFloat, slotCount: Int, boardWidth: CGFloat, slotSpacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your arrangement")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            HStack(spacing: slotSpacing) {
                ForEach(0 ..< vm.slots.count, id: \.self) { idx in
                    slotCell(index: idx, width: slotW)
                }
            }
            .frame(width: boardWidth)
        }
    }

    private func slotCell(index: Int, width: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.78),
                            Color.appBackground.opacity(0.42)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.55), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 4)
            if let value = vm.slots[index] {
                GlyphShapeView(shape: value)
                    .frame(width: width - 12, height: width - 12)
                    .onTapGesture {
                        vm.returnToBank(slotIndex: index)
                        selectedBankIndex = nil
                    }
            } else {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let pick = selectedBankIndex {
                            vm.placeFromBank(bankIndex: pick, slotIndex: index)
                            selectedBankIndex = nil
                        }
                    }
            }
        }
        .frame(width: width, height: width)
    }

    private func bankRowInner(boardWidth: CGFloat, slotSpacing: CGFloat) -> some View {
        let bankCount = max(vm.bank.count, 1)
        let pieceOuter = (boardWidth - CGFloat(bankCount - 1) * slotSpacing) / CGFloat(bankCount)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Carved pieces")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            HStack(spacing: slotSpacing) {
                ForEach(Array(vm.bank.enumerated()), id: \.element.id) { index, piece in
                    GlyphShapeView(shape: piece.shape)
                        .frame(width: pieceOuter - 16, height: pieceOuter - 16)
                        .shadow(color: Color.black.opacity(0.22), radius: 4, x: 0, y: 2)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appSurface.opacity(0.98),
                                            Color.appSurface.opacity(0.72)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    selectedBankIndex == index ? Color.appAccent : Color.appAccent.opacity(0.22),
                                    lineWidth: selectedBankIndex == index ? 3 : 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                        .onTapGesture {
                            selectedBankIndex = selectedBankIndex == index ? nil : index
                        }
                }
            }
            .frame(width: boardWidth)
        }
    }

    private var controls: some View {
        Button("Reset attempt") {
            didRecordFinish = false
            selectedBankIndex = nil
            vm.manualReset()
        }
        .buttonStyle(AdventureSecondaryButtonStyle())
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .foregroundStyle(Color.appTextPrimary)
        .adventureSecondaryChrome(cornerRadius: 14)
        .frame(maxWidth: .infinity, minHeight: GameLayout.minTap)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

private struct GlyphShapeView: View {
    let shape: Int

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let rect = CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.76, height: h * 0.76)
            switch shape % 4 {
            case 0:
                let path = Path(ellipseIn: rect)
                context.fill(path, with: .color(Color.appAccent))
            case 1:
                let path = Path(roundedRect: rect, cornerRadius: 6)
                context.fill(path, with: .color(Color.appPrimary))
            case 2:
                var path = Path()
                path.move(to: CGPoint(x: w / 2, y: h * 0.1))
                path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.5))
                path.addLine(to: CGPoint(x: w / 2, y: h * 0.9))
                path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.5))
                path.closeSubpath()
                context.fill(path, with: .color(Color.appAccent.opacity(0.85)))
            default:
                var path = Path()
                let r = min(w, h) / 2 * 0.78
                for i in 0 ..< 6 {
                    let angle = CGFloat(i) * .pi / 3 - .pi / 6
                    let px = w / 2 + cos(angle) * r
                    let py = h / 2 + sin(angle) * r
                    if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
                    else { path.addLine(to: CGPoint(x: px, y: py)) }
                }
                path.closeSubpath()
                context.fill(path, with: .color(Color.appPrimary.opacity(0.9)))
            }
        }
    }
}
