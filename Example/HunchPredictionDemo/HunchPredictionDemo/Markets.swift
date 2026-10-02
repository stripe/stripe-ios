//
//  Markets.swift
//  HunchPredictionDemo
//

import Foundation
import Observation
import SwiftUI

enum MarketCategory: String, CaseIterable, Identifiable {
    case trending = "Trending"
    case politics = "Politics"
    case economics = "Economics"
    case sports = "Sports"
    case culture = "Culture"
    case crypto = "Crypto"
    case climate = "Climate"
    case tech = "Tech"

    var id: String { rawValue }
}

enum ChartSpan: String, CaseIterable, Identifiable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case all = "ALL"

    var id: String { rawValue }

    var interval: TimeInterval {
        switch self {
        case .day: return 86_400
        case .week: return 7 * 86_400
        case .month: return 30 * 86_400
        case .all: return 120 * 86_400
        }
    }
}

struct Outcome: Identifiable {
    let id: String
    let name: String
    /// Probability in 0...1.
    var probability: Double
    /// History per span, oldest first, always `Market.historyLength` points.
    var history: [ChartSpan: [Double]]

    var yesCents: Int { max(1, min(99, Int((probability * 100).rounded()))) }
    var noCents: Int { max(1, min(99, 100 - yesCents + 1)) }
}

struct Market: Identifiable {
    static let historyLength = 90

    let id: String
    let title: String
    let category: MarketCategory
    let symbol: String
    let symbolColor: Color
    let closes: String
    let rules: String
    var volume: Double
    var outcomes: [Outcome]

    var isBinary: Bool { outcomes.count == 1 }
    var leading: Outcome { outcomes.max { $0.probability < $1.probability }! }

    func dayChange(for outcome: Outcome) -> Int {
        guard let first = outcome.history[.day]?.first else { return 0 }
        return Int(((outcome.probability - first) * 100).rounded())
    }
}

struct Position: Identifiable {
    let id = UUID()
    let marketTitle: String
    let outcomeName: String
    let side: Side
    let contracts: Int
    let averageCents: Int
    var currentCents: Int
    var settledWon: Bool?

    var cost: Double { Double(contracts * averageCents) / 100 }
    var value: Double {
        if let settledWon { return settledWon ? Double(contracts) : 0 }
        return Double(contracts * currentCents) / 100
    }
    var profit: Double { value - cost }
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

private func history(endingAt end: Double, span: ChartSpan, seed: UInt64) -> [Double] {
    var rng = SeededGenerator(seed: seed)
    let volatility: Double = switch span {
    case .day: 0.006
    case .week: 0.012
    case .month: 0.02
    case .all: 0.03
    }
    var values = [0.0]
    for _ in 1..<Market.historyLength {
        values.append(values[values.count - 1] + volatility * rng.gaussian())
    }
    // Smooth, then pin the last point to the current probability.
    let smoothed = values.indices.map { index -> Double in
        let slice = values[max(0, index - 2)...min(values.count - 1, index + 2)]
        return slice.reduce(0, +) / Double(slice.count)
    }
    let offset = end - smoothed[smoothed.count - 1]
    return smoothed.map { min(0.99, max(0.01, $0 + offset)) }
}

private func outcome(_ id: String, _ name: String, _ probability: Double, seed: UInt64) -> Outcome {
    Outcome(
        id: id,
        name: name,
        probability: probability,
        history: Dictionary(uniqueKeysWithValues: ChartSpan.allCases.enumerated().map { index, span in
            (span, history(endingAt: probability, span: span, seed: seed &+ UInt64(index * 97)))
        })
    )
}

@Observable
final class MarketStore {
    var markets: [Market]
    var positions: [Position]
    var cash: Double = 1_284.50
    private var ticker: Timer?
    private var rng = SeededGenerator(seed: 2026)

    init() {
        markets = [
            Market(id: "fed-dec", title: "Fed decision in December?", category: .economics,
                   symbol: "building.columns.fill", symbolColor: Color(red: 0.18, green: 0.5, blue: 0.93),
                   closes: "Dec 10", rules: "Resolves to the target range announced after the December FOMC meeting.",
                   volume: 48_200_000,
                   outcomes: [
                       outcome("cut25", "Cut 25bps", 0.62, seed: 1),
                       outcome("hold", "Hold", 0.34, seed: 2),
                       outcome("cut50", "Cut 50bps", 0.04, seed: 3),
                   ]),
            Market(id: "btc-150", title: "Bitcoin above $150k by Dec 31?", category: .crypto,
                   symbol: "bitcoinsign.circle.fill", symbolColor: .orange,
                   closes: "Dec 31", rules: "Resolves Yes if the BTC/USD reference rate is above $150,000 at 11:59pm ET.",
                   volume: 12_700_000, outcomes: [
     outcome("yes", "Yes", 0.38, seed: 11)]),
     Market(id: "nba", title: "NBA Champion 2027", category: .sports,
     symbol: "basketball.fill", symbolColor: Color(red: 0.95, green: 0.45, blue: 0.1),
     closes: "Jun 2027", rules: "Resolves to the team that wins the 2027 NBA Finals.",
     volume: 31_900_000,
     outcomes: [outcome("okc", "Oklahoma City", 0.29, seed: 21),
     outcome("den", "Denver", 0.18, seed: 22),
     outcome("nyk", "New York", 0.14, seed: 23),
     outcome("bos", "Boston", 0.12, seed: 24),
 ]),
            Market(id: "hurricane", title: "Another Atlantic hurricane before Nov 30?", category: .climate,
                   symbol: "hurricane", symbolColor: Color(red: 0.2, green: 0.6, blue: 0.75),
                   closes: "Nov 30", rules: "Resolves Yes if NHC names a new Atlantic hurricane before Nov 30.",
                   volume: 3_400_000, outcomes: [
     outcome("yes", "Yes", 0.71, seed: 31)]),
     Market(id: "ai-model", title: "Top AI model on the leaderboard end of year?", category: .tech,
     symbol: "sparkles", symbolColor: Color(red: 0.49, green: 0.36, blue: 0.99),
     closes: "Dec 31", rules: "Resolves to the top-ranked model on the public text leaderboard on Dec 31.",
     volume: 9_800_000,
     outcomes: [outcome("a", "Model A", 0.44, seed: 41),
     outcome("b", "Model B", 0.31, seed: 42),
     outcome("c", "Model C", 0.19, seed: 43),
 ]),
            Market(id: "box-office", title: "Holiday box office opening above $200M?", category: .culture,
                   symbol: "film.fill", symbolColor: Color(red: 0.85, green: 0.2, blue: 0.4),
                   closes: "Dec 21", rules: "Resolves Yes if the domestic opening weekend exceeds $200M.",
                   volume: 1_900_000, outcomes: [outcome("yes", "Yes", 0.55, seed: 51)]),
            Market(id: "cpi", title: "November CPI above 3.0%?", category: .economics,
                   symbol: "cart.fill", symbolColor: Color(red: 0.0, green: 0.62, blue: 0.43),
                   closes: "Dec 11", rules: "Resolves Yes if headline CPI YoY for November exceeds 3.0%.",
                   volume: 6_100_000, outcomes: [outcome("yes", "Yes", 0.27, seed: 61)]),
        ]
        positions = [
            Position(marketTitle: "Fed decision in December?", outcomeName: "Cut 25bps", side: .yes,
                     contracts: 120, averageCents: 48, currentCents: 62),
            Position(marketTitle: "Bitcoin above $150k by Dec 31?", outcomeName: "Yes", side: .no,
                     contracts: 80, averageCents: 55, currentCents: 63),
            Position(marketTitle: "World Series Champion 2026", outcomeName: "Los Angeles", side: .yes,
                     contracts: 400, averageCents: 31, currentCents: 100, settledWon: true),
        ]
    }

    var trending: [Market] { markets.sorted { $0.volume > $1.volume } }

    func markets(in category: MarketCategory) -> [Market] {
        category == .trending ? trending : markets.filter { $0.category == category }
    }

    func market(id: String) -> Market? { markets.first { $0.id == id } }

    var openPositions: [Position] { positions.filter { $0.settledWon == nil } }
    var settledWinnings: Double { positions.filter { $0.settledWon == true }.reduce(0) { $0 + $1.value } }
    var portfolioValue: Double { cash + openPositions.reduce(0) { $0 + $1.value } }

    func buy(market: Market, outcome: Outcome, side: Side, amount: Double) {
        let cents = side == .yes ? outcome.yesCents : outcome.noCents
        let contracts = Int(amount * 100 / Double(cents))
        guard contracts > 0 else { return }
        cash -= Double(contracts * cents) / 100
        positions.insert(Position(marketTitle: market.title, outcomeName: outcome.name, side: side,
                                  contracts: contracts, averageCents: cents, currentCents: cents), at: 0)
    }

    /// Nudges probabilities so the markets feel live.
    func startTicking() {
        guard ticker == nil else { return }
        ticker = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        for marketIndex in markets.indices {
            // Only move a few markets per tick, like real order flow.
            guard Double.random(in: 0..<1, using: &rng) < 0.45 else { continue }
            for outcomeIndex in markets[marketIndex].outcomes.indices {
                var outcome = markets[marketIndex].outcomes[outcomeIndex]
                let step = 0.012 * rng.gaussian()
                outcome.probability = min(0.97, max(0.02, outcome.probability + step))
                for span in ChartSpan.allCases {
                    var history = outcome.history[span] ?? []
                    if span == .day, !history.isEmpty {
                        history.removeFirst()
                        history.append(outcome.probability)
                    } else if !history.isEmpty {
                        history[history.count - 1] = outcome.probability
                    }
                    outcome.history[span] = history
                }
                markets[marketIndex].outcomes[outcomeIndex] = outcome
            }
            markets[marketIndex].volume += Double.random(in: 500...8_000, using: &rng)
        }
        for index in positions.indices where positions[index].settledWon == nil {
            if let market = markets.first(where: { $0.title == positions[index].marketTitle }),
               let outcome = market.outcomes.first(where: { $0.name == positions[index].outcomeName }) {
                positions[index].currentCents = positions[index].side == .yes ? outcome.yesCents : outcome.noCents
            }
        }
    }
}

extension Double {
    var compactVolume: String {
        "$" + formatted(.number.notation(.compactName).precision(.fractionLength(0...1))) + " vol"
    }
}
