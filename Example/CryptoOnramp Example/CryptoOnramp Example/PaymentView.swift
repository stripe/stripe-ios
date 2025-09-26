//
//  PaymentView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/17/25.
//

import PassKit
import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

@_spi(STP)
import StripePayments

@_spi(STP)
@_spi(AppearanceAPIAdditionsPreview)
import StripePaymentSheet

@_spi(STP)
import StripePaymentsUI

/// A view that allows input of a specified crypto purchase amount and payment method.
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

    private enum SelectedPaymentMethod {
        case applePay
        case existingPaymentToken(PaymentTokensResponse.PaymentToken)
        case newPaymentMethod(tokenId: String, type: PaymentMethodType, displayData: PaymentMethodDisplayData)
    }

    private enum PaymentMethodIcon {
        case systemName(String)
        case image(UIImage)
    }

    private struct Alert: Identifiable {
        var id: String { title + message }
        let title: String
        let message: String
    }

    private struct EditCurrencyAlert: Identifiable {
        let id = UUID()
    }
    /// The coordinator to use for collecting new payment methods and creating crypto payment tokens.
    let coordinator: CryptoOnrampCoordinator

    /// The unique id of the customer.
    let customerId: String

    /// The wallet being funded.
    let wallet: CustomerWalletsResponse.Wallet

    /// Upon success, this closure is called delivering the created onramp session, ready for checkout.
    let onContinue: (CreateOnrampSessionResponse) -> Void

    @Environment(\.isLoading) private var isLoading
    @Environment(\.locale) private var locale

    @State private var amountText: String = "0"
    @State private var shouldShowPaymentMethodSheet: Bool = false
    @State private var paymentTokens: [PaymentTokensResponse.PaymentToken] = []
    @State private var alert: Alert?
    @State private var selectedPaymentMethod: SelectedPaymentMethod?
    @State private var destinationCurrency: String = "usdc"
    @State private var editCurrencyAlert: EditCurrencyAlert?
    @State private var editingCurrencyText: String = ""

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
            }
        })
    }

    private var isPresentingEditCurrencyAlert: Binding<Bool> {
        Binding(get: {
            editCurrencyAlert != nil
        }, set: { newValue in
            if !newValue {
                editCurrencyAlert = nil
            }
        })
    }
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
        .delete,
    ]

    private var shouldDisableContinueButton: Bool {
        let amount = Double(amountText) ?? 0
        return isLoading.wrappedValue || selectedPaymentMethod == nil || amount <= 0
    }

    private var selectPaymentMethodButtonTitle: String {
        return switch selectedPaymentMethod {
        case .applePay:
            "Apple Pay"
        case let .existingPaymentToken(paymentToken):
            paymentToken.formattedNameAndLastFourDigits(dotCount: 1)
        case let .newPaymentMethod(_, _, displayData):
            displayData.sublabel ?? displayData.label
        case nil:
            "Select a payment method"
        }
    }

    @ViewBuilder
    private var selectPaymentMethodButtonIcon: some View {
        switch selectedPaymentMethod {
        case .applePay:
            makePaymentMethodIcon(systemImageName: "applelogo")
        case let .existingPaymentToken(paymentToken):
            if paymentToken.card != nil {
                makePaymentMethodIcon(systemImageName: "creditcard")
            } else {
                makePaymentMethodIcon(systemImageName: "building.columns")
            }
        case let .newPaymentMethod(_, type, _):
            switch type {
            case .applePay:
                makePaymentMethodIcon(systemImageName: "applelogo")
            case .card:
                makePaymentMethodIcon(systemImageName: "creditcard")
            case .bankAccount:
                makePaymentMethodIcon(systemImageName: "building.columns")
            default:
                makePaymentMethodIcon(systemImageName: "creditcard")
            }
        case nil:
            EmptyView()
        }
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("$" + (amountText.isEmpty ? "0" : amountText))
                    .font(.system(size: 56, weight: .bold))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .center)

                Button {
                    editingCurrencyText = destinationCurrency
                    editCurrencyAlert = EditCurrencyAlert()
                } label: {
                    HStack(spacing: 4) {
                        Text("to \(destinationCurrency)")
                            .font(.callout)
                            .foregroundColor(.secondary)

                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()

            makeSelectPaymentMethodButton()

            HStack(spacing: 12) {
                makePresetAmountButton(3)
                makePresetAmountButton(5)
                makePresetAmountButton(10)
            }
            .padding(.bottom, 8)

            makeKeypad()
                .padding(.bottom, 16)
        }
        .padding(.horizontal)
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            ZStack {
                if case .applePay = selectedPaymentMethod {
                    PayWithApplePayButton(.plain) {
                        continueWithApplePay()
                    }
                    .frame(height: 52)
                    .cornerRadius(8)
                } else {
                    Button("Continue") {
                        switch selectedPaymentMethod {
                        case let .existingPaymentToken(token):
                            createOnrampSession(withCryptoPaymentTokenId: token.id)
                        case let .newPaymentMethod(tokenId, _, _):
                            createOnrampSession(withCryptoPaymentTokenId: tokenId)
                        case .applePay: break
                        case nil: break
                        }

                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .disabled(shouldDisableContinueButton)
            .opacity(shouldDisableContinueButton ? 0.5 : 1)
            .padding()
        }
        .sheet(isPresented: $shouldShowPaymentMethodSheet) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Text("Pay with")
                        .font(.title2)
                        .bold()
                        .padding(.top, 8)

                    if !paymentTokens.isEmpty {
                        LazyVStack(spacing: 8) {
                            ForEach(paymentTokens) { token in
                                makePaymentMethodButton(using: token)
                            }
                        }
                    }

                    HStack {
                        VStack { Divider() }

                        Text("Add New")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        VStack { Divider() }
                    }

                    VStack(spacing: 8) {
                        if StripeAPI.deviceSupportsApplePay() {
                            makePaymentMethodButton(
                                title: "Apple Pay",
                                subtitle: "Instant",
                                icon: .systemName("applelogo")
                            ) {
                                selectedPaymentMethod = .applePay
                                shouldShowPaymentMethodSheet = false
                            }
                        }

                        makePaymentMethodButton(
                            title: "Add Debit / Credit Card",
                            subtitle: "1-5 minutes",
                            icon: .systemName("creditcard")
                        ) {
                            presentPaymentMethodSelector(for: .card)
                        }

                        makePaymentMethodButton(
                            title: "Add Bank Account",
                            subtitle: "Free",
                            icon: .systemName("building.columns"),
                            highlightSubtitle: true
                        ) {
                            presentPaymentMethodSelector(for: .bankAccount)
                        }
                    }
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            fetchPaymentTokens()
        }
        .alert(
            alert?.title ?? "Error",
            isPresented: isPresentingAlert,
            presenting: alert,
            actions: { _ in
                Button("OK") {}
            }, message: { alert in
                Text(alert.message)
            }
        )
        .alert(
            "Edit Destination Currency",
            isPresented: isPresentingEditCurrencyAlert,
            actions: {
                TextField("Currency (e.g. usdc)", text: $editingCurrencyText)
                    .textInputAutocapitalization(.never)

                Button("Save") {
                    let trimmed = editingCurrencyText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        destinationCurrency = trimmed
                    }
                    editCurrencyAlert = nil
                }

                Button("Cancel", role: .cancel) {
                    editCurrencyAlert = nil
                }
            },
            message: {
                Text("Enter the destination currency code (e.g. usdc, btc, eth)")
            }
        )
    }

    // MARK: - PaymentView

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
    private func makePaymentMethodButton(
        title: String,
        subtitle: String,
        icon: PaymentMethodIcon,
        highlightSubtitle: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                switch icon {
                case let .systemName(name):
                    makePaymentMethodIcon(systemImageName: name, useInlineStyle: false)
                case let .image(image):
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 36, maxHeight: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(highlightSubtitle ? .green : .secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground).opacity(0.7))
            )
        }
        .buttonStyle(.plain)
        // Fixes an issue in which scrolling the a sheet containing the button can
        // mistakenly trigger the button action.
        // https://developer.apple.com/forums/thread/763436?answerId=804853022#804853022
        .simultaneousGesture(TapGesture())
    }

    @ViewBuilder
    private func makePaymentMethodButton(using token: PaymentTokensResponse.PaymentToken) -> some View {
        let subtitle = token.formattedNameAndLastFourDigits()
        let action = {
            selectedPaymentMethod = .existingPaymentToken(token)
            shouldShowPaymentMethodSheet = false
        }

        if let card = token.card {
            let cardBrand = STPCard.brand(from: card.brand)
            let icon = STPImageLibrary.cardBrandImage(for: cardBrand)

            makePaymentMethodButton(
                title: "Card",
                subtitle: subtitle,
                icon: .image(icon),
                action: action
            )
        } else if let bankAccount = token.usBankAccount {
            let iconCode = PaymentSheetImageLibrary.bankIconCode(for: bankAccount.bankName)
            let icon = PaymentSheetImageLibrary.bankIcon(for: iconCode, iconStyle: .filled)

            makePaymentMethodButton(
                title: "Bank Account",
                subtitle: subtitle,
                icon: .image(icon),
                action: action
            )
        } else {
            EmptyView()
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
    private func makeSelectPaymentMethodButton() -> some View {
        HStack {
            Button {
                shouldShowPaymentMethodSheet = true
            } label: {
                HStack(spacing: 6) {
                    if selectedPaymentMethod != nil {
                        selectPaymentMethodButtonIcon
                    }

                    Text(selectPaymentMethodButtonTitle)
                        .font(.callout)
                        .bold()
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func makePaymentMethodIcon(systemImageName: String, useInlineStyle: Bool = true) -> some View {
        let backgroundDimension: CGFloat = useInlineStyle ? 22 : 40
        let fontSize: CGFloat = useInlineStyle ? 10 : 18
        let backgroundFillColor: UIColor = useInlineStyle ? .secondarySystemBackground : .systemBackground

        ZStack {
            Circle()
                .fill(Color(backgroundFillColor))
                .frame(width: backgroundDimension, height: backgroundDimension)
                .offset(y: 1)

            Image(systemName: systemImageName)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.primary)
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

    private func fetchPaymentTokens() {
        isLoading.wrappedValue = true
        Task {
            do {
                let response = try await APIClient.shared.fetchPaymentTokens(cryptoCustomerToken: customerId)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    paymentTokens = response.data
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                }
            }
        }
    }

    private func presentPaymentMethodSelector(for type: PaymentMethodType) {
        guard let viewController = UIApplication.shared.findTopViewController() else {
            alert = Alert(title: "Error", message: "Unable to find view controller to present from.")
            return
        }

        isLoading.wrappedValue = true

        Task {
            do {
                if let displayData = try await coordinator.collectPaymentMethod(type: type, from: viewController) {

                    await MainActor.run {
                        shouldShowPaymentMethodSheet = false
                    }

                    let token = try await coordinator.createCryptoPaymentToken()

                    await MainActor.run {
                        isLoading.wrappedValue = false
                        selectedPaymentMethod = .newPaymentMethod(tokenId: token, type: type, displayData: displayData)
                    }
                } else { // cancelled
                    await MainActor.run {
                        isLoading.wrappedValue = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "Payment method selection failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func continueWithApplePay() {
        guard let viewController = UIApplication.shared.findTopNavigationController() else {
            alert = Alert(title: "Error", message: "Unable to find view controller to present from.")
            return
        }

        let request = StripeAPI.paymentRequest(withMerchantIdentifier: "merchant.com.stripe.umbrella.test", country: "US", currency: "USD")
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "$\(amountText) usd + fees", amount: .zero, type: .pending)
        ]

        isLoading.wrappedValue = true

        Task {
            do {
                if try await coordinator.collectPaymentMethod(type: .applePay(paymentRequest: request), from: viewController) != nil {
                    let token = try await coordinator.createCryptoPaymentToken()

                    await MainActor.run {
                        // intentionally not flipping `isLoading`, since `createOnrampSession` will set it back.
                        createOnrampSession(withCryptoPaymentTokenId: token)
                    }
                } else { // cancelled
                    await MainActor.run {
                        isLoading.wrappedValue = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "Apple Pay failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func createOnrampSession(withCryptoPaymentTokenId cryptoPaymentTokenId: String) {
        isLoading.wrappedValue = true

        let request = CreateOnrampSessionRequest(
            paymentToken: cryptoPaymentTokenId,
            sourceAmount: Decimal(string: amountText) ?? 0,
            sourceCurrency: "usd", // <--- hardcoded for demo
            destinationCurrency: destinationCurrency,
            destinationNetwork: wallet.network,
            destinationCurrencies: [destinationCurrency],
            destinationNetworks: [wallet.network],
            walletAddress: wallet.walletAddress,
            cryptoCustomerId: customerId,
            customerIpAddress: "39.131.174.122" // <--- hardcoded for demo
        )

        Task {
            do {
                let response = try await APIClient.shared.createOnrampSession(requestObject: request)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    onContinue(response)
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "Failed to create onramp session", message: error.localizedDescription)
                }
            }
        }
    }
}

private extension STPCardFundingType {
    var displayNameWithBrand: String {
        switch self {
        case .credit: String.Localized.Funding.credit
        case .debit: String.Localized.Funding.debit
        case .prepaid: String.Localized.Funding.prepaid
        case .other: String.Localized.Funding.default
        @unknown default: ""
        }
    }

    init(_ typeString: String) {
        self = switch typeString {
        case "debit": .debit
        case "credit": .credit
        case "prepaid": .prepaid
        default: .other
        }
    }
}

private extension PaymentTokensResponse.PaymentToken {
    func formattedNameAndLastFourDigits(dotCount: Int = 4) -> String {
        let dots = String(repeating: "•", count: dotCount)
        if let card = card {
            let cardBrand = STPCard.brand(from: card.brand)
            let brandName = STPCardBrandUtilities.stringFrom(cardBrand)
            let fundingType = STPCardFundingType(card.funding)
            let formattedBrandName = String(format: fundingType.displayNameWithBrand, brandName ?? "")

            return "\(formattedBrandName) \(dots) \(card.last4)"
        } else if let bankAccount = usBankAccount {
            return "\(bankAccount.bankName) \(dots) \(bankAccount.last4)"
        } else {
            return ""
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        PaymentView(
            coordinator: coordinator,
            customerId: "cus_example",
            wallet: .init(
                id: "0",
                object: "",
                livemode: false,
                network: "solana",
                walletAddress: ""
            ),
            onContinue: { _ in }
        )
    }
}
