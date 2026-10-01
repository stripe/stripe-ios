//
//  HomeView.swift
//  HunchPredictionDemo
//

import SwiftUI

struct OrderIntent: Identifiable {
    let marketId: String
    let outcomeId: String
    var side: Side
    var id: String { "\(marketId)-\(outcomeId)" }
}

struct HomeView: View {
    @Environment(MarketStore.self) private var store
    @Binding var path: NavigationPath
    @Binding var order: OrderIntent?

    @State private var category: MarketCategory = .trending
    @State private var featuredScrub: Int?
    @State private var appeared = false
    @Namespace private var chipNamespace

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    if category == .trending, let featured = store.market(id: "fed-dec") {
                        FeaturedMarketCard(market: featured, scrubIndex: $featuredScrub) { outcome, side in
                            order = OrderIntent(marketId: featured.id, outcomeId: outcome.id, side: side)
                        }
                        .onTapGesture { path.append(featured.id) }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }

                    VStack(spacing: 12) {
                        ForEach(Array(store.markets(in: category).filter { category != .trending || $0.id != "fed-dec" }
                            .enumerated()), id: \.element.id) { index, market in
                            MarketCard(market: market) { outcome, side in
                                order = OrderIntent(marketId: market.id, outcomeId: outcome.id, side: side)
                            }
                            .onTapGesture { path.append(market.id) }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(Double(index) * 0.04),
                                       value: appeared)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                } header: {
                    categoryChips
                }
            }
        }
        .scrollDisabled(featuredScrub != nil)
        .background(Hunch.background)
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.startTicking()
            appeared = true
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: category)
    }

    private var header: some View {
        HStack {
            HunchWordmark()
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(Hunch.brand)
                Text(store.cash.dollars)
                    .font(.hunchNumber(15, .semibold))
                    .foregroundStyle(Hunch.text)
                    .contentTransition(.numericText(value: store.cash))
                    .animation(.snappy, value: store.cash)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Hunch.surface, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Hunch.background)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 22) {
                ForEach(MarketCategory.allCases) { item in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { category = item }
                    } label: {
                        VStack(spacing: 8) {
                            Text(item.rawValue)
                                .font(.hunch(15, category == item ? .semibold : .medium))
                                .foregroundStyle(category == item ? Hunch.text : Hunch.secondary)
                            ZStack {
                                Capsule().fill(.clear).frame(height: 3)
                                if category == item {
                                    Capsule()
                                        .fill(Hunch.text)
                                        .frame(height: 3)
                                        .matchedGeometryEffect(id: "chip", in: chipNamespace)
                                }
                            }
                        }
                        .fixedSize()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
        }
        .background(Hunch.background)
        .overlay(alignment: .bottom) { Rectangle().fill(Hunch.hairline).frame(height: 1) }
        .sensoryFeedback(.selection, trigger: category)
    }
}

private struct MarketHeader: View {
    let market: Market

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(market.symbolColor.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: market.symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(market.symbolColor)
            }
            Text(market.title)
                .font(.hunch(16, .semibold))
                .foregroundStyle(Hunch.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

private struct MarketFooter: View {
    let market: Market

    var body: some View {
        HStack(spacing: 6) {
            Text(market.volume.compactVolume)
                .contentTransition(.numericText(value: market.volume))
            Text("·")
            Text("Closes \(market.closes)")
            Spacer()
            Image(systemName: "bookmark")
        }
        .font(.hunch(12, .medium))
        .foregroundStyle(Hunch.secondary)
        .animation(.snappy, value: market.volume)
    }
}

struct MarketCard: View {
    let market: Market
    let onTrade: (Outcome, Side) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if market.isBinary, let outcome = market.outcomes.first {
                HStack(alignment: .top) {
                    MarketHeader(market: market)
                    ChanceGauge(probability: outcome.probability,
                                color: outcome.probability >= 0.5 ? Hunch.yes : Hunch.no)
                }
                HStack(spacing: 10) {
                    SidePriceButton(side: .yes, cents: outcome.yesCents) { onTrade(outcome, .yes) }
                    SidePriceButton(side: .no, cents: outcome.noCents) { onTrade(outcome, .no) }
                }
            } else {
                MarketHeader(market: market)
                VStack(spacing: 10) {
                    ForEach(market.outcomes.prefix(3)) { outcome in
                        OutcomeRow(outcome: outcome) { side in onTrade(outcome, side) }
                    }
                }
            }
            MarketFooter(market: market)
        }
        .padding(16)
        .background(Hunch.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Hunch.hairline, lineWidth: 1))
        .contentShape(Rectangle())
    }
}

struct OutcomeRow: View {
    let outcome: Outcome
    let onTrade: (Side) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(outcome.name)
                .font(.hunch(15, .medium))
                .foregroundStyle(Hunch.text)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text("\(outcome.yesCents)%")
                .font(.hunchNumber(16))
                .foregroundStyle(Hunch.text)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(outcome.yesCents)))
                .animation(.snappy, value: outcome.yesCents)
                .frame(width: 48, alignment: .trailing)
            SidePriceButton(side: .yes, cents: outcome.yesCents, compact: true) { onTrade(.yes) }
                .frame(width: 78)
            SidePriceButton(side: .no, cents: outcome.noCents, compact: true) { onTrade(.no) }
                .frame(width: 78)
        }
    }
}

struct FeaturedMarketCard: View {
    let market: Market
    @Binding var scrubIndex: Int?
    let onTrade: (Outcome, Side) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Featured", systemImage: "flame.fill")
                    .font(.hunch(12, .semibold))
                    .foregroundStyle(Hunch.no)
                Spacer()
                Text("LIVE")
                    .font(.hunch(11, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Hunch.no, in: Capsule())
            }
            MarketHeader(market: market)

            HStack(spacing: 14) {
                ForEach(Array(market.outcomes.enumerated()), id: \.element.id) { index, outcome in
                    let values = outcome.history[.week] ?? []
                    let shown = scrubIndex.flatMap { values.indices.contains($0) ? values[$0] : nil } ?? outcome.probability
                    HStack(spacing: 5) {
                        Circle().fill(Hunch.outcomePalette[index % 4]).frame(width: 7, height: 7)
                        Text(outcome.name).font(.hunch(12, .medium)).foregroundStyle(Hunch.secondary)
                        Text("\(Int((shown * 100).rounded()))%")
                            .font(.hunchNumber(13, .semibold))
                            .foregroundStyle(Hunch.text)
                            .contentTransition(.numericText(value: shown))
                    }
                }
            }
            .animation(.snappy(duration: 0.2), value: scrubIndex)

            ProbabilityChart(
                series: market.outcomes.enumerated().map { index, outcome in
                    ChartSeries(id: outcome.id, name: outcome.name, values: outcome.history[.week] ?? [],
                                color: Hunch.outcomePalette[index % 4])
                },
                scrubIndex: $scrubIndex
            )
            .frame(height: 150)
            .animation(.easeInOut(duration: 0.6), value: market.outcomes.map(\.probability))

            VStack(spacing: 10) {
                ForEach(market.outcomes) { outcome in
                    OutcomeRow(outcome: outcome) { side in onTrade(outcome, side) }
                }
            }
            MarketFooter(market: market)
        }
        .padding(16)
        .background(Hunch.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Hunch.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 16, y: 6)
        .contentShape(Rectangle())
    }
}
