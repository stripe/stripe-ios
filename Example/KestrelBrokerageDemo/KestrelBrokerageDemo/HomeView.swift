//
//  HomeView.swift
//  KestrelBrokerageDemo
//

import SwiftUI

struct HomeView: View {
    @Environment(Portfolio.self) private var portfolio
    @Binding var path: NavigationPath

    @State private var range: ChartRange = .day
    @State private var scrubIndex: Int?
    @State private var showPercent = false
    @State private var appeared = false

    var body: some View {
        let points = portfolio.series(for: range)
        let startValue = points.first?.value ?? 0
        let displayedPoint = scrubIndex.flatMap { points.indices.contains($0) ? points[$0] : nil } ?? points.last
        let displayedValue = displayedPoint?.value ?? portfolio.totalValue
        let change = displayedValue - startValue
        let isUp = (points.last?.value ?? 0) >= startValue

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header(value: displayedValue, change: change, start: startValue, point: displayedPoint)
                    .padding(.horizontal, 20)

                PortfolioChart(points: points, isUp: isUp, scrubIndex: $scrubIndex)
                    .frame(height: 230)
                    .padding(.top, 20)
                    .animation(.spring(response: 0.55, dampingFraction: 0.85), value: range)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(x: 1, y: appeared ? 1 : 0.2, anchor: .center)

                RangePicker(selection: $range, color: Theme.trend(isUp))
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .animation(.easeInOut(duration: 0.3), value: isUp)

                withdrawBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                buyingPower
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                holdings
                    .padding(.top, 28)
            }
            .padding(.bottom, 40)
        }
        .scrollDisabled(scrubIndex != nil)
        .background(Theme.background)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                KestrelWordmark()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { path.append(Route.account) } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .toolbarBackground(Theme.background, for: .navigationBar)
        .onAppear {
            portfolio.startTicking()
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1)) { appeared = true }
        }
    }

    private func header(value: Double, change: Double, start: Double, point: PricePoint?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Investing")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)

            Text(value, format: .currency(code: "USD"))
                .font(.rounded(40, .bold))
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText(value: value))
                .animation(.snappy(duration: 0.25), value: value)
                .monospacedDigit()

            HStack(spacing: 6) {
                Image(systemName: change >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 10))
                    .contentTransition(.symbolEffect(.replace))
                Text("\(change.signedCurrency) (\((start == 0 ? 0 : change / start).signedPercent))")
                    .contentTransition(.numericText(value: change))
                    .monospacedDigit()
                Text(scrubLabel(point))
                    .foregroundStyle(Theme.textSecondary)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.trend(change >= 0))
            .animation(.snappy(duration: 0.25), value: change)
        }
        .padding(.top, 4)
    }

    private func scrubLabel(_ point: PricePoint?) -> String {
        guard scrubIndex != nil, let point else { return range.changeLabel }
        let style: Date.FormatStyle = range == .day
            ? .dateTime.hour().minute()
            : .dateTime.month(.abbreviated).day().year()
        return point.date.formatted(style)
    }

    private var withdrawBanner: some View {
        Button { path.append(Route.payoutMethods) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.gain.opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.gain)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Add a bank to withdraw")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(portfolio.cash.currency) is ready to send to your bank.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.gain.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    private var buyingPower: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Buying power")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
                Text(portfolio.cash.currency)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Button { path.append(Route.withdraw) } label: {
                Text("Withdraw")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Theme.gain, in: Capsule())
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) { Divider().overlay(Theme.hairline) }
        .overlay(alignment: .bottom) { Divider().overlay(Theme.hairline) }
    }

    private var holdings: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Stocks")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            ForEach(Array(portfolio.holdings.enumerated()), id: \.element.id) { index, holding in
                HoldingRow(holding: holding, showPercent: $showPercent)
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.85).delay(0.25 + Double(index) * 0.05),
                        value: appeared
                    )
            }
        }
    }
}

private struct HoldingRow: View {
    let holding: Holding
    @Binding var showPercent: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(holding.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(holding.shares.formatted()) shares")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(width: 90, alignment: .leading)

            Sparkline(values: holding.sparkline, isUp: holding.isUp)
                .frame(height: 30)
                .frame(maxWidth: .infinity)

            Button {
                withAnimation(.snappy) { showPercent.toggle() }
            } label: {
                Group {
                    if showPercent {
                        Text(holding.changePercent.signedPercent)
                    } else {
                        Text(holding.price, format: .currency(code: "USD"))
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .contentTransition(.numericText(value: showPercent ? holding.changePercent : holding.price))
                .foregroundStyle(.black)
                .frame(width: 92)
                .padding(.vertical, 8)
                .background(Theme.trend(holding.isUp), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .animation(.snappy(duration: 0.3), value: holding.price)
            }
            .buttonStyle(PressableStyle())
            .sensoryFeedback(.impact(weight: .light), trigger: showPercent)
        }
        .padding(.vertical, 12)
    }
}

struct KestrelWordmark: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bird.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.gain)
            Text("kestrel")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
