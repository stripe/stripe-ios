//
//  MarketDetailView.swift
//  HunchPredictionDemo
//

import SwiftUI

struct MarketDetailView: View {
    @Environment(MarketStore.self) private var store
    let marketId: String
    @Binding var order: OrderIntent?

    @State private var span: ChartSpan = .week
    @State private var scrubIndex: Int?
    @State private var showRules = false
    @Namespace private var spanNamespace

    var body: some View {
        if let market = store.market(id: marketId) {
            content(market)
        }
    }

    private func content(_ market: Market) -> some View {
        let leading = market.leading
        let leadingIndex = market.outcomes.firstIndex { $0.id == leading.id } ?? 0
        let values = leading.history[span] ?? []
        let shown = scrubIndex.flatMap { values.indices.contains($0) ? values[$0] : nil } ?? leading.probability
        let change = Int(((shown - (values.first ?? shown)) * 100).rounded())

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(market.symbolColor.opacity(0.14))
                            .frame(width: 52, height: 52)
                        Image(systemName: market.symbol)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(market.symbolColor)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(market.category.rawValue.uppercased())
                            .font(.hunch(11, .bold))
                            .foregroundStyle(Hunch.secondary)
                            .tracking(0.6)
                        Text(market.title)
                            .font(.hunch(22, .bold))
                            .foregroundStyle(Hunch.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if !market.isBinary {
                        Text(leading.name)
                            .font(.hunch(15, .semibold))
                            .foregroundStyle(Hunch.outcomePalette[leadingIndex % 4])
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(Int((shown * 100).rounded()))% chance")
                            .font(.hunchNumber(34))
                            .foregroundStyle(Hunch.text)
                            .contentTransition(.numericText(value: shown))
                        HStack(spacing: 2) {
                            Image(systemName: change >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                                .font(.system(size: 9))
                            Text("\(abs(change))")
                                .contentTransition(.numericText(value: Double(change)))
                        }
                        .font(.hunch(15, .semibold))
                        .foregroundStyle(change >= 0 ? Hunch.yes : Hunch.no)
                    }
                    .animation(.snappy(duration: 0.2), value: shown)
                }

                ProbabilityChart(
                    series: market.outcomes.enumerated().map { index, outcome in
                        ChartSeries(id: outcome.id, name: outcome.name, values: outcome.history[span] ?? [],
                                    color: market.isBinary ? Hunch.brand : Hunch.outcomePalette[index % 4])
                    },
                    scrubIndex: $scrubIndex
                )
                .frame(height: 220)
                .animation(.spring(response: 0.55, dampingFraction: 0.85), value: span)

                spanPicker

                VStack(spacing: 0) {
                    ForEach(Array(market.outcomes.enumerated()), id: \.element.id) { index, outcome in
                        HStack(spacing: 10) {
                            if !market.isBinary {
                                Circle().fill(Hunch.outcomePalette[index % 4]).frame(width: 8, height: 8)
                            }
                            OutcomeRow(outcome: outcome) { side in
                                order = OrderIntent(marketId: market.id, outcomeId: outcome.id, side: side)
                            }
                        }
                        .padding(.vertical, 12)
                        if index < market.outcomes.count - 1 { Divider().overlay(Hunch.hairline) }
                    }
                }

                stats(market)

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showRules.toggle() }
                    } label: {
                        HStack {
                            Text("Rules summary").font(.hunch(16, .semibold))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(showRules ? 180 : 0))
                        }
                        .foregroundStyle(Hunch.text)
                    }
                    if showRules {
                        Text(market.rules)
                            .font(.hunch(15))
                            .foregroundStyle(Hunch.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(16)
                .background(Hunch.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(16)
            .padding(.bottom, 90)
        }
        .scrollDisabled(scrubIndex != nil)
        .background(Hunch.background)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                SidePriceButton(side: .yes, cents: leading.yesCents) {
                    order = OrderIntent(marketId: market.id, outcomeId: leading.id, side: .yes)
                }
                SidePriceButton(side: .no, cents: leading.noCents) {
                    order = OrderIntent(marketId: market.id, outcomeId: leading.id, side: .no)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private var spanPicker: some View {
        HStack(spacing: 6) {
            ForEach(ChartSpan.allCases) { item in
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { span = item }
                } label: {
                    Text(item.rawValue)
                        .font(.hunch(13, .semibold))
                        .foregroundStyle(span == item ? .white : Hunch.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background {
                            if span == item {
                                Capsule().fill(Hunch.text).matchedGeometryEffect(id: "span", in: spanNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .sensoryFeedback(.selection, trigger: span)
    }

    private func stats(_ market: Market) -> some View {
        HStack {
            stat("Volume", market.volume.compactVolume.replacingOccurrences(of: " vol", with: ""))
            Spacer()
            stat("Closes", market.closes)
            Spacer()
            stat("Traders", "\((Int(market.volume) / 410).formatted(.number.notation(.compactName)))")
        }
        .padding(16)
        .background(Hunch.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.hunch(12, .medium)).foregroundStyle(Hunch.secondary)
            Text(value).font(.hunchNumber(16, .semibold)).foregroundStyle(Hunch.text)
        }
    }
}
