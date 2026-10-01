//
//  OrderTicketView.swift
//  HunchPredictionDemo
//

import SwiftUI

struct OrderTicketView: View {
    @Environment(MarketStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var intent: OrderIntent

    @State private var amountText = "25"
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var didBuy = false
    @State private var confettiTrigger = 0

    private var amount: Double { Double(amountText) ?? 0 }

    var body: some View {
        if let market = store.market(id: intent.marketId),
           let outcome = market.outcomes.first(where: { $0.id == intent.outcomeId }) {
            ZStack {
                if didBuy {
                    success(market: market, outcome: outcome)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else {
                    ticket(market: market, outcome: outcome)
                        .transition(.opacity)
                }
                ConfettiView(trigger: confettiTrigger)
                    .allowsHitTesting(false)
            }
            .background(Hunch.background)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: didBuy)
        }
    }

    private func ticket(market: Market, outcome: Outcome) -> some View {
        let cents = intent.side == .yes ? outcome.yesCents : outcome.noCents
        let contracts = Int(amount * 100 / Double(max(cents, 1)))
        let payout = Double(contracts)

        return VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text(market.title)
                    .font(.hunch(15, .semibold))
                    .foregroundStyle(Hunch.secondary)
                    .multilineTextAlignment(.center)
                if !market.isBinary {
                    Text(outcome.name).font(.hunch(17, .bold)).foregroundStyle(Hunch.text)
                }
            }
            .padding(.top, 8)

            sidePicker(outcome: outcome)

            VStack(spacing: 4) {
                Text("$\(amountText.isEmpty ? "0" : amountText)")
                    .font(.hunchNumber(56))
                    .foregroundStyle(Hunch.text)
                    .contentTransition(.numericText(value: amount))
                    .animation(.snappy(duration: 0.2), value: amountText)
                HStack(spacing: 4) {
                    Text("To win")
                        .foregroundStyle(Hunch.secondary)
                    Text(payout.dollars)
                        .foregroundStyle(Hunch.yes)
                        .contentTransition(.numericText(value: payout))
                        .animation(.snappy(duration: 0.25), value: payout)
                }
                .font(.hunch(17, .semibold))
                Text("\(contracts) contracts · avg \(cents)¢")
                    .font(.hunch(13, .medium))
                    .foregroundStyle(Hunch.secondary)
                    .contentTransition(.numericText(value: Double(contracts)))
            }

            HStack(spacing: 8) {
                ForEach([1, 10, 100], id: \.self) { increment in
                    Button("+$\(increment)") {
                        amountText = String(Int(amount) + increment)
                    }
                    .font(.hunch(14, .semibold))
                    .foregroundStyle(Hunch.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Hunch.surface, in: Capsule())
                    .buttonStyle(HunchPressStyle())
                }
            }

            Keypad(text: $amountText)

            holdToBuy(side: intent.side, enabled: contracts > 0 && amount <= store.cash) {
                store.buy(market: market, outcome: outcome, side: intent.side, amount: amount)
                confettiTrigger += 1
                didBuy = true
            }
            Text("Cash available \(store.cash.dollars)")
                .font(.hunch(12, .medium))
                .foregroundStyle(Hunch.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func sidePicker(outcome: Outcome) -> some View {
        HStack(spacing: 8) {
            ForEach([Side.yes, .no], id: \.rawValue) { side in
                let cents = side == .yes ? outcome.yesCents : outcome.noCents
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { intent.side = side }
                } label: {
                    Text("\(side.rawValue) \(cents)¢")
                        .font(.hunch(16, .semibold))
                        .foregroundStyle(intent.side == side ? .white : side.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(intent.side == side ? side.color : side.tint,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(HunchPressStyle())
            }
        }
        .sensoryFeedback(.selection, trigger: intent.side)
    }

    private func holdToBuy(side: Side, enabled: Bool, onComplete: @escaping () -> Void) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(enabled ? Hunch.text : Hunch.hairline)
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(side.color)
                    .frame(width: proxy.size.width * holdProgress)
            }
            Text(isHolding ? "Keep holding…" : "Hold to buy \(side.rawValue)")
                .font(.hunch(17, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.8, maximumDistance: 40) {
            guard enabled else { return }
            onComplete()
        } onPressingChanged: { pressing in
            guard enabled else { return }
            isHolding = pressing
            withAnimation(pressing ? .linear(duration: 0.8) : .spring(response: 0.3, dampingFraction: 0.8)) {
                holdProgress = pressing ? 1 : 0
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isHolding) { _, new in new }
        .sensoryFeedback(.success, trigger: didBuy) { _, new in new }
    }

    private func success(market: Market, outcome: Outcome) -> some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle().fill(intent.side.tint).frame(width: 110, height: 110)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(intent.side.color)
                    .symbolEffect(.bounce, value: didBuy)
            }
            Text("Order filled")
                .font(.hunch(28, .bold))
                .foregroundStyle(Hunch.text)
            Text("You bought \(intent.side.rawValue) on \(market.isBinary ? market.title : outcome.name).")
                .font(.hunch(16))
                .foregroundStyle(Hunch.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            HunchPrimaryButton(title: "Done") { dismiss() }
        }
        .padding(24)
    }
}

private struct Keypad: View {
    @Binding var text: String

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(keys, id: \.self) { key in
                Button { press(key) } label: {
                    Group {
                        if key == "⌫" {
                            Image(systemName: "delete.left")
                        } else {
                            Text(key)
                        }
                    }
                    .font(.hunchNumber(24, .medium))
                    .foregroundStyle(Hunch.text)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(HunchPressStyle(scale: 0.9))
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: text)
    }

    private func press(_ key: String) {
        switch key {
        case "⌫":
            text = String(text.dropLast())
        case ".":
            if !text.contains(".") { text += text.isEmpty ? "0." : "." }
        default:
            if text == "0" { text = key } else if text.count < 6 { text += key }
        }
    }
}

/// A short burst of falling confetti.
struct ConfettiView: View {
    let trigger: Int

    @State private var pieces: [Piece] = []

    struct Piece: Identifiable {
        let id = UUID()
        let color: Color
        let x: CGFloat
        let drift: CGFloat
        let spin: Double
        let delay: Double
        let size: CGSize
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPiece(piece: piece, height: proxy.size.height)
                        .position(x: piece.x * proxy.size.width, y: -20)
                }
            }
        }
        .onChange(of: trigger) {
            let colors = Hunch.outcomePalette + [Hunch.no, .yellow]
            pieces = (0..<70).map { _ in
                Piece(color: colors.randomElement()!,
                      x: .random(in: 0.05...0.95),
                      drift: .random(in: -80...80),
                      spin: .random(in: 180...720),
                      delay: .random(in: 0...0.25),
                      size: CGSize(width: .random(in: 6...10), height: .random(in: 10...16)))
            }
        }
    }
}

private struct ConfettiPiece: View {
    let piece: ConfettiView.Piece
    let height: CGFloat
    @State private var fall = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size.width, height: piece.size.height)
            .rotationEffect(.degrees(fall ? piece.spin : 0))
            .offset(x: fall ? piece.drift : 0, y: fall ? height + 40 : 0)
            .opacity(fall ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: 1.6).delay(piece.delay)) { fall = true }
            }
    }
}
