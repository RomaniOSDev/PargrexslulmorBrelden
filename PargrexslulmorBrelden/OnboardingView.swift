//
//  OnboardingView.swift
//  PargrexslulmorBrelden
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var page = 0
    @State private var animateArt = false

    var body: some View {
        GeometryReader { geo in
            let pad = balancedVerticalPadding(screenHeight: geo.size.height)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: pad)

                    illustrationSection(width: geo.size.width)
                        .padding(.horizontal, GameLayout.horizontalPadding)

                    onboardingPageIndicator
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    textAndActionsCard
                        .padding(.horizontal, GameLayout.horizontalPadding)

                    Color.clear.frame(height: max(pad, 28))
                }
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
        }
        .background(AdventureScreenBackground())
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                animateArt = true
            }
        }
        .onChange(of: page) { _ in
            animateArt = false
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                animateArt = true
            }
        }
    }

    /// Centers the stack when there is extra height (ScrollView spacers are unreliable).
    private func balancedVerticalPadding(screenHeight: CGFloat) -> CGFloat {
        let estimatedContent: CGFloat = 590
        return max(20, (screenHeight - estimatedContent) * 0.45)
    }

    private func illustrationSection(width: CGFloat) -> some View {
        let cardHeight = min(320, max(240, width * 0.72))

        return VStack(spacing: 14) {
            TabView(selection: $page) {
                OnboardingPageTempleIllustration(animate: animateArt)
                    .tag(0)
                OnboardingPageForestIllustration(animate: animateArt)
                    .tag(1)
                OnboardingPageCavernIllustration(animate: animateArt)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: cardHeight)
        }
        .padding(10)
        .adventureRaisedCard(cornerRadius: 28, borderOpacity: 0.42)
    }

    private var onboardingPageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< 3, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Color.appPrimary : Color.appTextSecondary.opacity(0.38))
                    .frame(width: index == page ? 22 : 9, height: 9)
                    .animation(.easeInOut(duration: 0.28), value: page)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of 3")
    }

    private var textAndActionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(pageTitle)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            Text(pageBody)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
                .lineSpacing(7)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Color.appAccent.opacity(0.35))
                .frame(height: 1)
                .padding(.vertical, 20)

            HStack(spacing: 12) {
                if page < 2 {
                    Button("Skip") {
                        progress.finishOnboarding()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(minHeight: GameLayout.minTap)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .adventureSecondaryChrome(cornerRadius: 14)
                }

                Button(page < 2 ? "Next" : "Begin") {
                    if page < 2 {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            page += 1
                        }
                    } else {
                        progress.finishOnboarding()
                    }
                }
                .font(.system(page < 2 ? .body : .headline, design: .rounded).weight(.bold))
                .buttonStyle(AdventurePrimaryButtonStyle())
                .foregroundStyle(Color.appBackground)
                .frame(minHeight: GameLayout.minTap)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, page < 2 ? 12 : 16)
                .padding(.vertical, 14)
                .adventurePrimaryChrome(cornerRadius: 14)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adventureRaisedCard(cornerRadius: 26, borderOpacity: 0.38)
    }

    private var pageTitle: String {
        switch page {
        case 0: return "Ruins Await"
        case 1: return "Paths Between Trees"
        default: return "Listen Before You Step"
        }
    }

    private var pageBody: String {
        switch page {
        case 0:
            return "Slide carved glyphs into place to reveal hidden corridors. Each stage adds new patterns to decipher."
        case 1:
            return "Trace glowing trails across the woodland map. Quests grow longer as you learn the rhythm of the routes."
        default:
            return "Follow the true tone through the dark. Deeper stages weave decoy pulses—stay focused on the real signal."
        }
    }

}

// MARK: - Illustrations

private struct OnboardingPageTempleIllustration: View {
    let animate: Bool

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.2), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 160
            )

            Canvas { context, size in
                let w = size.width
                let h = size.height
                var arch = Path()
                arch.move(to: CGPoint(x: w * 0.25, y: h * 0.72))
                arch.addQuadCurve(to: CGPoint(x: w * 0.75, y: h * 0.72), control: CGPoint(x: w * 0.5, y: h * 0.35))
                arch.addLine(to: CGPoint(x: w * 0.75, y: h * 0.9))
                arch.addLine(to: CGPoint(x: w * 0.25, y: h * 0.9))
                arch.closeSubpath()
                context.stroke(arch, with: .color(Color.appAccent), lineWidth: 3.5)

                let pillarL = Path(roundedRect: CGRect(x: w * 0.22, y: h * 0.45, width: w * 0.08, height: h * 0.35), cornerRadius: 4)
                let pillarR = Path(roundedRect: CGRect(x: w * 0.7, y: h * 0.45, width: w * 0.08, height: h * 0.35), cornerRadius: 4)
                context.fill(pillarL, with: .color(Color.appPrimary.opacity(0.9)))
                context.fill(pillarR, with: .color(Color.appPrimary.opacity(0.9)))
            }
            .padding(.horizontal, 20)
            .scaleEffect(animate ? 1 : 0.94)
            .opacity(animate ? 1 : 0.7)
            .animation(.easeInOut(duration: 0.55), value: animate)
        }
    }
}

private struct OnboardingPageForestIllustration: View {
    let animate: Bool

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.appAccent.opacity(0.18), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 10,
                endRadius: 180
            )

            Canvas { context, size in
                let w = size.width
                let h = size.height
                for i in 0 ..< 5 {
                    let x = w * (0.18 + CGFloat(i) * 0.16)
                    let trunk = Path(roundedRect: CGRect(x: x, y: h * 0.55, width: w * 0.05, height: h * 0.28), cornerSize: CGSize(width: 3, height: 3))
                    context.fill(trunk, with: .color(Color.appPrimary.opacity(0.65)))
                    let canopy = Path(ellipseIn: CGRect(x: x - w * 0.04, y: h * 0.32, width: w * 0.13, height: h * 0.22))
                    context.fill(canopy, with: .color(Color.appAccent.opacity(0.6)))
                }
                var trail = Path()
                trail.move(to: CGPoint(x: w * 0.12, y: h * 0.82))
                trail.addCurve(
                    to: CGPoint(x: w * 0.88, y: h * 0.78),
                    control1: CGPoint(x: w * 0.35, y: h * 0.55),
                    control2: CGPoint(x: w * 0.62, y: h * 0.95)
                )
                context.stroke(trail, with: .color(Color.appTextPrimary.opacity(0.75)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            }
            .padding(.horizontal, 20)
            .offset(y: animate ? 0 : 10)
            .opacity(animate ? 1 : 0.72)
            .animation(.spring(response: 0.5, dampingFraction: 0.72), value: animate)
        }
    }
}

private struct OnboardingPageCavernIllustration: View {
    let animate: Bool

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.15), Color.appSurface.opacity(0.4)],
                center: .center,
                startRadius: 10,
                endRadius: 200
            )

            Canvas { context, size in
                let w = size.width
                let h = size.height
                for i in 0 ..< 6 {
                    let y = h * (0.35 + CGFloat(i) * 0.08)
                    var wave = Path()
                    wave.move(to: CGPoint(x: w * 0.1, y: y))
                    for x in stride(from: 0.1, through: 0.9, by: 0.02) {
                        let px = w * CGFloat(x)
                        let offset = sin((Double(x) + (animate ? 1 : 0)) * 10) * 6
                        wave.addLine(to: CGPoint(x: px, y: y + CGFloat(offset)))
                    }
                    context.stroke(wave, with: .color(Color.appAccent.opacity(0.85)), lineWidth: 2.5)
                }
            }
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.8), value: animate)
        }
    }
}
