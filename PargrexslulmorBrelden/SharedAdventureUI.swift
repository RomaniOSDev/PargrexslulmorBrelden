//
//  SharedAdventureUI.swift
//  PargrexslulmorBrelden
//

import SwiftUI

// MARK: - Depth & chrome

struct AdventureRaisedCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    var borderOpacity: Double = 0.38
    /// Lighter styling for dense grids (fewer layers / one shadow) — better scroll & navigation FPS.
    var compact: Bool = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if compact {
            compactBody(content: content)
        } else {
            standardBody(content: content)
        }
    }

    private func standardBody(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background(
                shape.fill(
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
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(borderOpacity),
                            Color.appPrimary.opacity(borderOpacity * 0.35),
                            Color.appAccent.opacity(borderOpacity * 0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 5)
    }

    private func compactBody(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background(shape.fill(Color.appSurface.opacity(0.9)))
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.appAccent.opacity(borderOpacity), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 2)
    }
}

struct AdventureInsetWell: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.14),
                                Color.appBackground.opacity(0.52)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.black.opacity(0.28), Color.white.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 2)
    }
}

extension View {
    func adventureRaisedCard(cornerRadius: CGFloat = 16, borderOpacity: Double = 0.38, compact: Bool = false) -> some View {
        modifier(AdventureRaisedCard(cornerRadius: cornerRadius, borderOpacity: borderOpacity, compact: compact))
    }

    func adventureInsetWell(cornerRadius: CGFloat = 18) -> some View {
        modifier(AdventureInsetWell(cornerRadius: cornerRadius))
    }

    /// Primary CTA: vertical gradient, specular edge, glowing shadow.
    func adventurePrimaryChrome(cornerRadius: CGFloat = 14) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(
            shape.fill(
                LinearGradient(
                    colors: [
                        Color.appPrimary,
                        Color.appPrimary.opacity(0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.22), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
        )
        .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, x: 0, y: 5)
    }

    /// Secondary / surface actions.
    func adventureSecondaryChrome(cornerRadius: CGFloat = 14) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(
            shape.fill(
                LinearGradient(
                    colors: [
                        Color.appSurface.opacity(0.96),
                        Color.appSurface.opacity(0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.12),
                        Color.appAccent.opacity(0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        )
        .shadow(color: Color.black.opacity(0.14), radius: 7, x: 0, y: 4)
    }
}

struct AdventurePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AdventureSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct StarRatingRow: View {
    let filled: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 3, id: \.self) { i in
                starView(index: i)
            }
        }
        .accessibilityLabel("Stars \(filled) out of three")
    }

    @ViewBuilder
    private func starView(index i: Int) -> some View {
        if i < filled {
            Text("★")
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.appAccent.opacity(0.55), radius: 6, y: 2)
        } else {
            Text("★")
                .font(.title3)
                .foregroundStyle(Color.appTextSecondary.opacity(0.72))
        }
    }
}

struct AdventureScreenBackground: View {
    var body: some View {
        ZStack {
            Color.appBackground
            LinearGradient(
                colors: [
                    Color.appPrimary.opacity(0.2),
                    Color.appBackground.opacity(0.94),
                    Color.appAccent.opacity(0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.16)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .compositingGroup()
        .ignoresSafeArea()
    }
}

/// Shared expedition artwork for home and list cards.
struct ExpeditionGlyph: View {
    let kind: ActivityKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.34),
                            Color.appPrimary.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Canvas { context, size in
                let w = size.width
                let h = size.height
                switch kind {
                case .temple:
                    var door = Path()
                    door.move(to: CGPoint(x: w * 0.22, y: h * 0.78))
                    door.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.78), control: CGPoint(x: w * 0.5, y: h * 0.32))
                    door.addLine(to: CGPoint(x: w * 0.78, y: h * 0.9))
                    door.addLine(to: CGPoint(x: w * 0.22, y: h * 0.9))
                    door.closeSubpath()
                    context.stroke(door, with: .color(Color.appAccent), lineWidth: 2.5)
                case .forest:
                    var trail = Path()
                    trail.move(to: CGPoint(x: w * 0.18, y: h * 0.78))
                    trail.addCurve(
                        to: CGPoint(x: w * 0.82, y: h * 0.72),
                        control1: CGPoint(x: w * 0.38, y: h * 0.45),
                        control2: CGPoint(x: w * 0.62, y: h * 0.95)
                    )
                    context.stroke(trail, with: .color(Color.appAccent), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                case .cavern:
                    for i in 0 ..< 3 {
                        let y = h * (0.42 + CGFloat(i) * 0.12)
                        var wave = Path()
                        wave.move(to: CGPoint(x: w * 0.12, y: y))
                        for s in stride(from: 0.12, through: 0.88, by: 0.04) {
                            let px = w * CGFloat(s)
                            let offset = sin(Double(s) * 14) * 4
                            wave.addLine(to: CGPoint(x: px, y: y + CGFloat(offset)))
                        }
                        context.stroke(wave, with: .color(Color.appAccent), lineWidth: 2)
                    }
                }
            }
        }
    }
}
