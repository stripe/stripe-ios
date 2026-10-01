//
//  PortfolioView.swift
//  HunchPredictionDemo
//

import SwiftUI

struct PortfolioView: View {
    @Environment(MarketStore.self) private var store
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                balanceCard
                if store.settledWinnings > 0 { winningsBanner }

                Text("Positions")
                    .font(.hunch(20, .bold))
                    .foregroundStyle(Hunch.text)
                    .padding(.top, 4)

                VStack(spacing: 0) {
                    ForEach(Array(store.positions.enumerated()), id: \.element.id) { index, position in
                        PositionRow(position: position)
                            .padding(.vertical, 14)
                        if index < store.positions.count - 1 { Divider().overlay(Hunch.hairline) }
                    }
                }
            }
            .padding(16)
        }
        .background(Hunch.background)
        .navigationTitle("Portfolio")
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.positions.count)
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Portfolio value")
                    .font(.hunch(14, .medium))
                    .foregroundStyle(Hunch.secondary)
                Text(store.portfolioValue.dollars)
                    .font(.hunchNumber(38))
                    .foregroundStyle(Hunch.text)
                    .contentTransition(.numericText(value: store.portfolioValue))
                    .animation(.snappy, value: store.portfolioValue)
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cash").font(.hunch(13, .medium)).foregroundStyle(Hunch.secondary)
                    Text(store.cash.dollars).font(.hunchNumber(17, .semibold)).foregroundStyle(Hunch.text)
                }
                Spacer()
                Button { path.append(CashOutRoute.withdraw) } label: {
                    Label("Cash out", systemImage: "arrow.down.to.line")
                        .font(.hunch(15, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Hunch.text, in: Capsule())
                }
                .buttonStyle(HunchPressStyle())
            }
        }
        .padding(18)
        .background(Hunch.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var winningsBanner: some View {
        Button { path.append(CashOutRoute.withdraw) } label: {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Hunch.yes, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("You won \(store.settledWinnings.dollars)")
                        .font(.hunch(16, .semibold))
                        .foregroundStyle(Hunch.text)
                    Text("World Series settled. Cash out to your bank or card.")
                        .font(.hunch(13))
                        .foregroundStyle(Hunch.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Hunch.secondary)
            }
            .padding(14)
            .background(Hunch.yesTint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(HunchPressStyle(scale: 0.98))
    }
}

private struct PositionRow: View {
    let position: Position

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(position.marketTitle)
                    .font(.hunch(15, .semibold))
                    .foregroundStyle(Hunch.text)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(position.side.rawValue)
                        .font(.hunch(12, .bold))
                        .foregroundStyle(position.side.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(position.side.tint, in: Capsule())
                    if position.outcomeName != "Yes" {
                        Text(position.outcomeName).font(.hunch(13, .medium)).foregroundStyle(Hunch.secondary)
                    }
                    Text("\(position.contracts) @ \(position.averageCents)¢")
                        .font(.hunch(13, .medium))
                        .foregroundStyle(Hunch.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(position.value.dollars)
                    .font(.hunchNumber(16, .semibold))
                    .foregroundStyle(Hunch.text)
                    .contentTransition(.numericText(value: position.value))
                if position.settledWon == true {
                    Text("Won").font(.hunch(13, .semibold)).foregroundStyle(Hunch.yes)
                } else {
                    Text(position.profit.signedDollars)
                        .font(.hunch(13, .semibold))
                        .foregroundStyle(position.profit >= 0 ? Hunch.yes : Hunch.no)
                        .contentTransition(.numericText(value: position.profit))
                }
            }
            .animation(.snappy, value: position.currentCents)
        }
    }
}
