//
//  MarketData.swift
//  KestrelBrokerageDemo
//

import Foundation
import Observation

enum ChartRange: String, CaseIterable, Identifiable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case year = "1Y"
    case all = "ALL"

    var id: String { rawValue }

    var changeLabel: String {
        switch self {
        case .day: return "Today"
        case .week: return "Past week"
        case .month: return "Past month"
        case .threeMonths: return "Past 3 months"
        case .year: return "Past year"
        case .all: return "All time"
        }
    }

    fileprivate var span: TimeInterval {
        switch self {
        case .day: return 6.5 * 3600
        case .week: return 7 * 86_400
        case .month: return 30 * 86_400
        case .threeMonths: return 91 * 86_400
        case .year: return 365 * 86_400
        case .all: return 4 * 365 * 86_400
        }
    }

    fileprivate var volatility: Double {
        switch self {
        case .day: return 0.0011
        case .week: return 0.0024
        case .month: return 0.0042
        case .threeMonths: return 0.007
        case .year: return 0.012
        case .all: return 0.021
        }
    }

    fileprivate var drift: Double {
        switch self {
        case .day: return 0.00012
        case .week: return -0.0003
        case .month: return 0.0007
        case .threeMonths: return 0.0011
        case .year: return 0.0026
        case .all: return 0.0062
        }
    }
}

struct PricePoint {
    let date: Date
    let value: Double
}

/// Deterministic random numbers so the demo looks the same on every run.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func gaussian() -> Double {
        let u1 = max(Double.random(in: 0..<1, using: &self), .leastNonzeroMagnitude)
        let u2 = Double.random(in: 0..<1, using: &self)
        return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }
}

enum SeriesGenerator {
    /// Every series has the same number of points so the chart can morph between ranges.
    static let pointCount = 120

    /// Builds a random walk that ends exactly at `endValue`.
    static func series(endingAt endValue: Double, range: ChartRange, seed: UInt64) -> [PricePoint] {
        var rng = SeededGenerator(seed: seed)
        var values = [1.0]
        for _ in 1..<pointCount {
            let step = range.drift + range.volatility * rng.gaussian()
            values.append(values[values.count - 1] * (1 + step))
        }
        values = smoothed(values)
        let scale = endValue / values[values.count - 1]
        let end = Date()
        let interval = range.span / Double(pointCount - 1)
        return values.enumerated().map { index, value in
            PricePoint(
                date: end.addingTimeInterval(-Double(pointCount - 1 - index) * interval),
                value: value * scale
            )
        }
    }

    /// Builds a sparkline that starts at the open price and ends at the current price.
    static func sparkline(from open: Double, to close: Double, seed: UInt64) -> [Double] {
        var rng = SeededGenerator(seed: seed)
        var walk = [0.0]
        for _ in 1..<60 {
            walk.append(walk[walk.count - 1] + 0.0025 * rng.gaussian())
        }
        walk = smoothed(walk)
        let drift = walk[walk.count - 1]
        return walk.enumerated().map { index, value in
            let t = Double(index) / Double(walk.count - 1)
            return (open + (close - open) * t) * (1 + value - drift * t)
        }
    }

    /// A light moving average so lines read as a trend rather than noise.
    private static func smoothed(_ values: [Double], window: Int = 2) -> [Double] {
        values.indices.map { index in
            let lower = max(0, index - window)
            let upper = min(values.count - 1, index + window)
            let slice = values[lower...upper]
            return slice.reduce(0, +) / Double(slice.count)
        }
    }
}

struct Holding: Identifiable {
    let symbol: String
    let name: String
    let shares: Double
    var price: Double
    let openPrice: Double
    var sparkline: [Double]

    var id: String { symbol }
    var change: Double { price - openPrice }
    var changePercent: Double { change / openPrice }
    var isUp: Bool { change >= 0 }
    var marketValue: Double { price * shares }
}

private struct HoldingSeed {
    let symbol: String
    let name: String
    let shares: Double
    let price: Double
    let openPrice: Double
}

@Observable
final class Portfolio {
    var holdings: [Holding]
    var cash: Double = 2_450.00
    private var ticker: Timer?
    private var tickRNG = SeededGenerator(seed: 42)

    init() {
        let seeds: [HoldingSeed] = [
            .init(symbol: "NVDA", name: "NVIDIA", shares: 42, price: 186.40, openPrice: 183.12),
            .init(symbol: "AAPL", name: "Apple", shares: 30, price: 254.63, openPrice: 256.10),
            .init(symbol: "TSLA", name: "Tesla", shares: 12, price: 442.79, openPrice: 431.55),
            .init(symbol: "AMZN", name: "Amazon", shares: 18, price: 231.08, openPrice: 229.94),
            .init(symbol: "SPY", name: "S&P 500 ETF", shares: 9, price: 668.21, openPrice: 664.90),
            .init(symbol: "COIN", name: "Coinbase", shares: 7, price: 348.66, openPrice: 356.02),
        ]
        holdings = seeds.enumerated().map { index, seed in
            Holding(
                symbol: seed.symbol,
                name: seed.name,
                shares: seed.shares,
                price: seed.price,
                openPrice: seed.openPrice,
                sparkline: SeriesGenerator.sparkline(from: seed.openPrice, to: seed.price, seed: UInt64(index + 7))
            )
        }
    }

    var investedValue: Double { holdings.reduce(0) { $0 + $1.marketValue } }
    var totalValue: Double { investedValue + cash }
    var openValue: Double { holdings.reduce(0) { $0 + $1.openPrice * $1.shares } + cash }

    func series(for range: ChartRange) -> [PricePoint] {
        let seed: UInt64 = switch range {
        case .day: 11
        case .week: 23
        case .month: 5
        case .threeMonths: 19
        case .year: 3
        case .all: 29
        }
        return SeriesGenerator.series(endingAt: totalValue, range: range, seed: seed)
    }

    /// Nudges prices so the portfolio feels live.
    func startTicking() {
        guard ticker == nil else { return }
        ticker = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopTicking() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        for index in holdings.indices {
            let step = 0.0009 * tickRNG.gaussian()
            let newPrice = (holdings[index].price * (1 + step) * 100).rounded() / 100
            holdings[index].price = newPrice
            holdings[index].sparkline.removeFirst()
            holdings[index].sparkline.append(newPrice)
        }
    }
}

extension Double {
    var currency: String { formatted(.currency(code: "USD")) }

    var signedCurrency: String {
        let formatted = abs(self).formatted(.currency(code: "USD"))
        return self >= 0 ? "+\(formatted)" : "-\(formatted)"
    }

    var signedPercent: String {
        let formatted = abs(self).formatted(.percent.precision(.fractionLength(2)))
        return self >= 0 ? "+\(formatted)" : "-\(formatted)"
    }
}
