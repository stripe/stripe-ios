//
//  ProbabilityChart.swift
//  HunchPredictionDemo
//

import SwiftUI

/// A fixed-length vector of doubles that SwiftUI can interpolate, so lines morph point-by-point.
struct AnimatableVector: VectorArithmetic {
    var values: [Double]

    static var zero: AnimatableVector { .init(values: []) }

    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector { combine(lhs, rhs, +) }
    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector { combine(lhs, rhs, -) }

    mutating func scale(by rhs: Double) { values = values.map { $0 * rhs } }

    var magnitudeSquared: Double { values.reduce(0) { $0 + $1 * $1 } }

    private static func combine(
        _ lhs: AnimatableVector,
        _ rhs: AnimatableVector,
        _ op: (Double, Double) -> Double
    ) -> AnimatableVector {
        let count = max(lhs.values.count, rhs.values.count)
        return .init(values: (0..<count).map { index in
            op(index < lhs.values.count ? lhs.values[index] : 0,
               index < rhs.values.count ? rhs.values[index] : 0)
        })
    }
}

/// Draws values already normalized to 0...1 as a smooth line.
struct ProbabilityLine: Shape {
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
            if index == positions.count - 1 { path.addQuadCurve(to: current, control: current) }
        }
        return path
    }
}

struct ChartSeries: Identifiable {
    let id: String
    let name: String
    let values: [Double]
    let color: Color
}

struct ProbabilityChart: View {
    let series: [ChartSeries]
    @Binding var scrubIndex: Int?
    var showsGrid = true
    var lineWidth: CGFloat = 2.4

    @State private var pulse = false

    /// Shared scale across all lines, snapped to 10% gridlines.
    private var bounds: (lower: Double, upper: Double) {
        let all = series.flatMap(\.values)
        let lower = max(0, ((all.min() ?? 0) * 10).rounded(.down) / 10)
        let upper = min(1, ((all.max() ?? 1) * 10).rounded(.up) / 10)
        return upper - lower < 0.2 ? (max(0, lower - 0.1), min(1, upper + 0.1)) : (lower, upper)
    }

    private func normalized(_ values: [Double]) -> [Double] {
        let (lower, upper) = bounds
        return values.map { ($0 - lower) / max(upper - lower, 0.01) }
    }

    var body: some View {
        GeometryReader { proxy in
            let plotWidth = proxy.size.width - (showsGrid ? 40 : 10)
            let height = proxy.size.height
            let count = series.first?.values.count ?? 0
            let fraction = scrubIndex.map { CGFloat($0) / CGFloat(max(count - 1, 1)) } ?? 1

            ZStack(alignment: .topLeading) {
                if showsGrid { grid(width: proxy.size.width, plotWidth: plotWidth, height: height) }

                ForEach(series) { line in
                    let points = AnimatableVector(values: normalized(line.values))
                    ProbabilityLine(points: points)
                        .stroke(line.color.opacity(scrubIndex == nil ? 0 : 0.22),
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                        .frame(width: plotWidth)
                    ProbabilityLine(points: points)
                        .trim(from: 0, to: fraction)
                        .stroke(line.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                        .frame(width: plotWidth)
                }

                if let scrubIndex, count > 0 {
                    let x = plotWidth * CGFloat(scrubIndex) / CGFloat(count - 1)
                    Rectangle()
                        .fill(Hunch.secondary.opacity(0.5))
                        .frame(width: 1, height: height)
                        .offset(x: x - 0.5)
                    ForEach(series) { line in
                        let y = height * (1 - CGFloat(normalized(line.values)[scrubIndex]))
                        Circle()
                            .fill(line.color)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .offset(x: x - 5, y: y - 5)
                    }
                } else {
                    ForEach(series) { line in
                        if let last = normalized(line.values).last {
                            livePulse(color: line.color)
                                .offset(x: plotWidth - 6, y: height * (1 - CGFloat(last)) - 6)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard count > 1 else { return }
                        let x = min(max(value.location.x, 0), plotWidth)
                        let index = Int((x / plotWidth * CGFloat(count - 1)).rounded())
                        if index != scrubIndex { scrubIndex = index }
                    }
                    .onEnded { _ in withAnimation(.easeOut(duration: 0.2)) { scrubIndex = nil } }
            )
        }
        .sensoryFeedback(.selection, trigger: scrubIndex) { _, new in new != nil }
        .onAppear { pulse = true }
    }

    private func grid(width: CGFloat, plotWidth: CGFloat, height: CGFloat) -> some View {
        let (lower, upper) = bounds
        let steps = max(1, Int(((upper - lower) * 10).rounded()))
        let stride = steps > 5 ? 2 : 1
        return ZStack(alignment: .topLeading) {
            ForEach(Array(Swift.stride(from: 0, through: steps, by: stride)), id: \.self) { step in
                let value = lower + Double(step) / 10
                let y = height * (1 - CGFloat((value - lower) / max(upper - lower, 0.01)))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: plotWidth, y: y))
                }
                .stroke(Hunch.hairline, style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                Text("\(Int((value * 100).rounded()))%")
                    .font(.hunch(11, .medium))
                    .foregroundStyle(Hunch.secondary)
                    .position(x: plotWidth + 20, y: y)
            }
        }
    }

    private func livePulse(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 12, height: 12)
                .scaleEffect(pulse ? 2.4 : 1)
                .opacity(pulse ? 0 : 1)
                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
            Circle().fill(color).frame(width: 8, height: 8)
        }
        .frame(width: 12, height: 12)
    }
}

/// Small probability gauge used on market cards.
struct ChanceGauge: View {
    let probability: Double
    var color: Color = Hunch.brand

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(Hunch.hairline, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(90))
            Circle()
                .trim(from: 0.12, to: 0.12 + 0.76 * probability)
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: probability)
            VStack(spacing: -2) {
                Text("\(Int((probability * 100).rounded()))%")
                    .font(.hunchNumber(15))
                    .foregroundStyle(Hunch.text)
                    .contentTransition(.numericText(value: probability))
                    .animation(.snappy, value: probability)
                Text("chance")
                    .font(.hunch(9, .medium))
                    .foregroundStyle(Hunch.secondary)
            }
        }
        .frame(width: 58, height: 58)
    }
}
