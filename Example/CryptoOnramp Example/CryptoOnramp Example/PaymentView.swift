//
//  PaymentView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/17/25.
//

import SwiftUI

struct PaymentView: View {
    private enum NumberPadKey: String, Identifiable {
        case zero
        case one
        case two
        case three
        case four
        case five
        case six
        case seven
        case eight
        case nine
        case decimalSeparator
        case delete

        // MARK: - Identifiable

        var id: String {
            rawValue
        }
    }

    let onContinue: () -> Void

    @Environment(\.isLoading) private var isLoading
    @Environment(\.locale) private var locale

    @State private var amountText: String = "0"

    // This example UI is intended for USD ($) only, but we respect the
    // current locale’s decimal separator.
    //
    // Additionally, we don’t use a currency number formatter while
    // editing in order to allow fully typing a dollar and cents amount
    // without auto-suffixing trailing zeros, which could interrupt
    // the edits a user is making.
    private static let decimalSeparator: String = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        return formatter.decimalSeparator ?? "."
    }()

    private static let keys: [NumberPadKey] = [
        .one,
        .two,
        .three,
        .four,
        .five,
        .six,
        .seven,
        .eight,
        .nine,
        .decimalSeparator,
        .zero,
        .delete
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("$" + (amountText.isEmpty ? "0" : amountText))
                .font(.system(size: 56, weight: .bold))
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            makePaymentMethodButton()
                .padding(.bottom, 16)

            HStack(spacing: 12) {
                makePresetAmountButton(50)
                makePresetAmountButton(100)
                makePresetAmountButton(250)
            }
            .padding(.bottom, 8)

            makeKeypad()
                .padding(.bottom, 16)
        }
        .padding(.horizontal)
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading.wrappedValue)
            .opacity(isLoading.wrappedValue ? 0.5 : 1)
            .padding()
        }
    }

    @ViewBuilder
    private func labelRepresentation(for key: NumberPadKey) -> some View {
        switch key {
        case .zero: Text("0")
        case .one: Text("1")
        case .two: Text("2")
        case .three: Text("3")
        case .four: Text("4")
        case .five: Text("5")
        case .six: Text("6")
        case .seven: Text("7")
        case .eight: Text("8")
        case .nine: Text("9")
        case .decimalSeparator: Text(Self.decimalSeparator)
        case .delete: Image(systemName: "delete.left")
        }
    }

    @ViewBuilder
    private func makeKeypad() -> some View {
        let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Self.keys, id: \.self) { key in
                Button {
                    handleKey(key)
                } label: {
                    labelRepresentation(for: key)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(height: 56)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func makePresetAmountButton(_ dollarAmount: Int) -> some View {
        Button {
            amountText = "\(dollarAmount)"
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))

                Text("$\(dollarAmount)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func makePaymentMethodButton() -> some View {
        HStack {
            Button {

            } label: {
                HStack(spacing: 6) {
                    Text("Select a payment method")
                        .bold()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Input Handling

    private func handleKey(_ key: NumberPadKey) {
        switch key {
        case .decimalSeparator: insertDecimalSeparator()
        case .delete: deleteLast()
        case .zero: insertDigit(0)
        case .one: insertDigit(1)
        case .two: insertDigit(2)
        case .three: insertDigit(3)
        case .four: insertDigit(4)
        case .five: insertDigit(5)
        case .six: insertDigit(6)
        case .seven: insertDigit(7)
        case .eight: insertDigit(8)
        case .nine: insertDigit(9)
        }
    }

    private func insertDigit(_ d: Int) {
        // If currently "0" and we have no separator yet, replace leading zero with non-zero digit.
        if amountText == "0" && d != 0 && !amountText.contains(Self.decimalSeparator) {
            amountText = "\(d)"
            return
        }

        // Limit to two fractional digits if decimal is present.
        if let range = amountText.range(of: Self.decimalSeparator) {
            let fractionalDigitCount = amountText[range.upperBound...].count
            if fractionalDigitCount >= 2 { return }
        }

        // Avoid multiple leading zeros without a decimal.
        if !amountText.contains(Self.decimalSeparator) && amountText == "0" && d == 0 {
            return
        }

        amountText.append("\(d)")
    }

    private func insertDecimalSeparator() {
        if amountText.isEmpty {
            amountText = "0" + Self.decimalSeparator
        } else if !amountText.contains(Self.decimalSeparator) {
            amountText.append(contentsOf: Self.decimalSeparator)
        }
    }

    private func deleteLast() {
        guard !amountText.isEmpty else {
            return
        }

        amountText.removeLast()

        if amountText.isEmpty {
            amountText = "0"
        }
    }
}

#Preview {
    PaymentView(onContinue: {})
}
