//
//  PortfolioChart.swift
//  KestrelBrokerageDemo
//

import SwiftUI

/// A fixed-length vector of doubles that SwiftUI can interpolate, so line shapes morph point-by-point.
struct AnimatableVector: VectorArithmetic {
    var values: [Double]

    static var zero: AnimatableVector { .init(values: []) }

    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        combine(lhs, rhs, +)
    }

    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        combine(lhs, rhs, -)
    }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }

    private static func combine(
        _ lhs: AnimatableVector,
        _ rhs: AnimatableVector,
        _ op: (Double, Double) -> Double
    ) -> AnimatableVector {
        let count = max(lhs.values.count, rhs.values.count)
        return .init(values: (0..<count).map { index in
            op(
                index < lhs.values.count ? lhs.values[index] : 0,
                index < rhs.values.count ? rhs.values[index] : 0
            )
        })
    }
}

/// Draws normalized (0...1) values as a smooth line.
struct LineShape: Shape {
    var points: AnimatableVector

    var animatableData: AnimatableVector {
        get { points }
        set { points = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let values = points.values
        guard values.count > 1 else { return Path() }
        let step = rect.width / CGFloat(values.count - 1)
        let positions = values.enumerated().map { index, value in
            CGPoint(x: CGFloat(index) * step, y: rect.height * (1 - CGFloat(value)))
        }

        var path = Path()
        path.move(to: positions[0])
        for index in 1..<positions.count {
            let previous = positions[index - 1]
            let current = positions[index]
            let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: previous)
            if index == positions.count - 1 {
                path.addQuadCurve(to: current, control: current)
            }
        }
        return path
    }
}

private func normalize(_ values: [Double]) -> [Double] {
    guard let minValue = values.min(), let maxValue = values.max(), maxValue > minValue else {
        return values.map { _ in 0.5 }
    }
    // Leave headroom so the line never touches the top or bottom edge.
    return values.map { 0.08 + 0.84 * ($0 - minValue) / (maxValue - minValue) }
}

struct PortfolioChart: View {
    let points: [PricePoint]
    let isUp: Bool
    @Binding var scrubIndex: Int?

    @State private var pulse = false

    private var normalized: [Double] { normalize(points.map(\.value)) }

    var body: some View {
        GeometryReader { proxy in
            // Inset the plot so the live indicator never clips at the trailing edge.
            let width = proxy.size.width - 14
            let height = proxy.size.height
            let values = normalized
            let color = Theme.trend(isUp)
            let fraction = scrubIndex.map { CGFloat($0) / CGFloat(max(values.count - 1, 1)) } ?? 1

            ZStack(alignment: .topLeading) {
                baseline(height: height)

                // Everything after the scrub position fades back, like a timeline cursor.
                LineShape(points: .init(values: values))
                    .stroke(color.opacity(scrubIndex == nil ? 0 : 0.25),
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .frame(width: width)

                LineShape(points: .init(values: values))
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .shadow(color: color.opacity(0.45), radius: 8, y: 2)
                    .frame(width: width)

                if let scrubIndex, values.indices.contains(scrubIndex) {
                    let x = width * CGFloat(scrubIndex) / CGFloat(values.count - 1)
                    let y = height * (1 - CGFloat(values[scrubIndex]))
                    Rectangle()
                        .fill(Theme.textSecondary.opacity(0.6))
                        .frame(width: 1, height: height)
                        .offset(x: x - 0.5)
                    Circle()
                        .fill(color)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(.black, lineWidth: 2))
                        .offset(x: x - 5.5, y: y - 5.5)
                } else if let last = values.last {
                    livePulse(color: color)
                        .offset(x: width - 6, y: height * (1 - CGFloat(last)) - 6)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let clampedX = min(max(value.location.x, 0), width)
                        let index = Int((clampedX / width * CGFloat(values.count - 1)).rounded())
                        if index != scrubIndex { scrubIndex = index }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) { scrubIndex = nil }
                    }
            )
        }
        .sensoryFeedback(.selection, trigger: scrubIndex) { _, new in new != nil }
        .onAppear { pulse = true }
    }

    private func baseline(height: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: height * 0.55))
            path.addLine(to: CGPoint(x: 10_000, y: height * 0.55))
        }
        .stroke(Theme.textSecondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [1, 5]))
    }

    private func livePulse(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: 12, height: 12)
                .scaleEffect(pulse ? 2.6 : 1)
                .opacity(pulse ? 0 : 1)
                .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .frame(width: 12, height: 12)
        }
    }
}

struct Sparkline: View {
    let values: [Double]
    let isUp: Bool

    var body: some View {
        LineShape(points: .init(values: normalize(values)))
            .stroke(Theme.trend(isUp), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .animation(.easeInOut(duration: 0.6), value: values)
    }
}

struct RangePicker: View {
    @Binding var selection: ChartRange
    let color: Color
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ChartRange.allCases) { range in
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        selection = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(selection == range ? .black : color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if selection == range {
                                Capsule()
                                    .fill(color)
                                    .matchedGeometryEffect(id: "range", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selection)
    }
}
