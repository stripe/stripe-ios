//
//  ApplePayPrefillView.swift
//  CryptoOnramp Example
//

import PassKit
import StripeCore
import SwiftUI

@_spi(STP)
import StripeUICore

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// The entry point for "Apple Pay Prefill Mode": a single screen where the user enters a purchase amount and wallet
/// address, then taps Apple Pay once to collect payment info, derive KYC info from it, register or authorize the
/// Link user behind the scenes, attach that KYC info, register the wallet address, and create the onramp session —
/// landing directly on the payment summary screen without ever seeing the Log In / Sign Up, KYC info, or wallet
/// selection screens.
struct ApplePayPrefillView: View {
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

    private struct EditCurrencyAlert: Identifiable {
        let id = UUID()
    }

    private enum SourceCurrency: String, CaseIterable, Identifiable {
        case usd
        case eur
        case cad
        case cop
        case php

        var displayName: String {
            rawValue.uppercased()
        }

        var amountPrefix: String {
            switch self {
            case .usd:
                "$"
            case .eur:
                "€"
            case .cad:
                "CAD "
            case .cop:
                "COP "
            case .php:
                "PHP "
            }
        }

        // MARK: - Identifiable

        var id: String {
            rawValue
        }
    }

    /// A fixed password used to silently create/access a demo backend session for this example app. Apple Pay does
    /// not provide a password, and this mode intentionally never shows a login screen for the user to supply one.
    private static let demoBackendPassword = "ApplePayPrefillDemo!2026"

    /// The coordinator used for payment collection, registration, and authentication.
    let coordinator: CryptoOnrampCoordinator?

    /// The flow coordinator used to advance to the next steps once the purchase completes.
    let flowCoordinator: CryptoOnrampFlowCoordinator

    /// Whether livemode is enabled.
    let livemode: Bool

    /// Specifies an alert originating from this view to display by the parent.
    @Binding var alert: Alert?

    @Environment(\.isLoading) private var isLoading

    @State private var amountText: String = "0"
    @State private var sourceCurrency: SourceCurrency = .usd
    @State private var destinationCurrency: String = "usdc"
    @State private var editCurrencyAlert: EditCurrencyAlert?
    @State private var editingCurrencyText: String = ""
    @State private var destinationNetwork: CryptoNetwork = .solana
    @State private var walletAddress: String = ""
    @State private var kycRecoveryLevels: KYCRecoveryFlowView.Levels?
    @State private var pendingWalletOwnershipVerificationCryptoPaymentTokenId: String?
    @State private var isPresentingWalletOwnershipVerificationAlert = false
    @State private var walletOwnershipVerificationSession: WalletOwnershipVerificationSession?

    // This example UI respects the current locale’s decimal separator.
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

    private var isButtonDisabled: Bool {
        let amount = Double(amountText) ?? 0
        return isLoading.wrappedValue
            || coordinator == nil
            || amount <= 0
            || walletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text(sourceCurrency.amountPrefix + (amountText.isEmpty ? "0" : amountText))
                    .font(.system(size: 56, weight: .bold))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 0) {
                    Picker(selection: $sourceCurrency) {
                        ForEach(SourceCurrency.allCases) { currency in
                            Text(currency.displayName).tag(currency)
                        }
                    } label: {
                        Text(sourceCurrency.displayName)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .pickerStyle(.menu)

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
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Network")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Network", selection: $destinationNetwork) {
                    ForEach(CryptoNetwork.allCases, id: \.rawValue) { network in
                        Text(network.rawValue.localizedCapitalized).tag(network)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Wallet Address")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                TextField("Enter wallet address", text: $walletAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.bottom, 16)

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
            PayWithApplePayButton(.plain) {
                payWithApplePay()
            }
            .frame(height: 52)
            .cornerRadius(8)
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled ? 0.5 : 1)
            .padding()
        }
        .alert(
            "Edit Destination Currency",
            isPresented: isPresentingEditCurrencyAlert,
            actions: {
                TextField("Currency (e.g. usdc)", text: $editingCurrencyText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

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
        .sheet(item: $kycRecoveryLevels) { kycRecoveryLevels in
            if let coordinator {
                KYCRecoveryFlowView(
                    coordinator: coordinator,
                    levels: kycRecoveryLevels
                ) {
                    alert = Alert(
                        title: "Verification complete",
                        message: "Please try the transaction again."
                    )
                }
                .environment(\.isLoading, isLoading)
            }
        }
        .walletOwnershipVerificationRequiredAlert(
            isPresented: $isPresentingWalletOwnershipVerificationAlert,
            onVerify: {
                verifyWalletOwnershipForPendingCreateOnrampSession()
            },
            onCancel: {
                pendingWalletOwnershipVerificationCryptoPaymentTokenId = nil
            }
        )
        .sheet(item: $walletOwnershipVerificationSession) { session in
            if let coordinator {
                WalletOwnershipVerificationSheet(
                    session: session,
                    coordinator: coordinator
                ) {
                    retryPendingCreateOnrampSession()
                }
            }
        }
    }

    // MARK: - Input Handling

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
    private func makePresetAmountButton(_ amount: Int) -> some View {
        Button {
            amountText = "\(amount)"
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))

                Text("\(sourceCurrency.amountPrefix)\(amount)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

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

    // MARK: - Actions

    private func payWithApplePay() {
        guard let coordinator, let viewController = UIApplication.shared.findTopNavigationController() else {
            alert = Alert(title: "Error", message: "Unable to find view controller to present from.")
            return
        }

        let request = StripeAPI.paymentRequest(
            withMerchantIdentifier: "merchant.com.stripe.umbrella.test",
            country: "US",
            currency: sourceCurrency.displayName
        )
        request.requiredBillingContactFields = [.name, .postalAddress, .emailAddress, .phoneNumber]
        // Billing contact email/phone come from the Apple ID's stored contact card, with no way to edit them in the
        // sheet. Requesting these as shipping contact fields too surfaces editable fields (e.g. in the simulator, to
        // enter mock values), and `KycInfo.init?(payment:)` falls back to the shipping contact when needed.
        request.requiredShippingContactFields = [.name, .postalAddress, .emailAddress, .phoneNumber]
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: "\(sourceCurrency.amountPrefix)\(amountText) \(sourceCurrency.rawValue) + fees",
                amount: .zero,
                type: .pending
            ),
        ]

        isLoading.wrappedValue = true

        Task {
            do {
                let result = try await coordinator.collectPaymentMethod(type: .applePay(paymentRequest: request), from: viewController)
                switch result {
                case .canceled:
                    await MainActor.run {
                        isLoading.wrappedValue = false
                    }
                case let .completed(_, kycInfo):
                    try await proceed(with: kycInfo, coordinator: coordinator, viewController: viewController)
                @unknown default:
                    await MainActor.run {
                        isLoading.wrappedValue = false
                        alert = Alert(title: "Apple Pay failed", message: "Received an unexpected result while collecting payment method.")
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

    private func proceed(with kycInfo: KycInfo?, coordinator: CryptoOnrampCoordinator, viewController: UINavigationController) async throws {
        guard let kycInfo, let email = kycInfo.email else {
            await MainActor.run {
                isLoading.wrappedValue = false
                alert = Alert(
                    title: "Missing email",
                    message: "Apple Pay did not return an email address. Requires an Apple Pay account with an email on the billing or shipping contact."
                )
            }
            return
        }

        let country = kycInfo.address?.country ?? "US"
        let fullName = [kycInfo.firstName, kycInfo.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
            .nonEmpty
        let e164Phone = kycInfo.phone.flatMap { PhoneNumber(number: $0.digitsOnly, countryCode: country)?.string(as: .e164) }

        do {
            // Silently establish a demo backend session for this example app. This is separate from Link
            // authentication and only exists so this demo's backend calls (e.g. creating the onramp session) have a
            // bearer token; it never presents any UI.
            try await signUpOrLogIn(email: email)

            if try await coordinator.hasLinkAccount(with: email) {
                // Returning Link user: log in directly, skipping the Log In / Sign Up screen entirely.
                let authIntentResponse = try await APIClient.shared.createAuthIntent()
                let authorizationResult = try await coordinator.authorize(linkAuthIntentId: authIntentResponse.authIntentId, from: viewController)

                switch authorizationResult {
                case let .consented(cryptoCustomerId):
                    try await APIClient.shared.saveUser(cryptoCustomerId: cryptoCustomerId)
                    // Best-effort: a returning user may already have KYC info attached.
                    try? await coordinator.attachKYCInfo(info: kycInfo)
                    try await finishPurchase(coordinator: coordinator)
                case .denied:
                    await MainActor.run {
                        isLoading.wrappedValue = false
                        alert = Alert(title: "Authorization Denied", message: "Authorization was denied.")
                    }
                case .canceled:
                    await MainActor.run {
                        isLoading.wrappedValue = false
                    }
                @unknown default:
                    await MainActor.run {
                        isLoading.wrappedValue = false
                    }
                }
            } else {
                // New Link user: go through the same registration + phone verification steps as the previous
                // (non-prefill) Link registration flow, just driven by Apple Pay-collected info instead of manual entry.
                guard let e164Phone else {
                    await MainActor.run {
                        isLoading.wrappedValue = false
                        alert = Alert(
                            title: "Missing phone number",
                            message: "Apple Pay did not return a usable phone number, which is required to register a new Link user."
                        )
                    }
                    return
                }

                try await coordinator.registerLinkUser(
                    email: email,
                    fullName: fullName,
                    phone: e164Phone,
                    country: country
                )

                let authIntentResponse = try await APIClient.shared.createAuthIntent()
                let authorizationResult = try await coordinator.authorize(linkAuthIntentId: authIntentResponse.authIntentId, from: viewController)

                switch authorizationResult {
                case let .consented(cryptoCustomerId):
                    try await APIClient.shared.saveUser(cryptoCustomerId: cryptoCustomerId)
                    try await coordinator.attachKYCInfo(info: kycInfo)
                    try await finishPurchase(coordinator: coordinator)
                case .denied:
                    await MainActor.run {
                        isLoading.wrappedValue = false
                        alert = Alert(title: "Authorization Denied", message: "Authorization was denied.")
                    }
                case .canceled:
                    await MainActor.run {
                        isLoading.wrappedValue = false
                    }
                @unknown default:
                    await MainActor.run {
                        isLoading.wrappedValue = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                isLoading.wrappedValue = false
                if let cryptoError = error as? CryptoOnrampCoordinator.Error, case .invalidPhoneFormat = cryptoError {
                    alert = Alert(title: "Registration failed", message: "Apple Pay returned a phone number that could not be converted to E.164 format.")
                } else {
                    alert = Alert(title: "Registration failed", message: error.localizedDescription)
                }
            }
        }
    }

    /// Registers the user-entered wallet address, creates a crypto payment token for the already-collected Apple
    /// Pay payment method, and creates the onramp session.
    private func finishPurchase(coordinator: CryptoOnrampCoordinator) async throws {
        let address = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        try await coordinator.registerWalletAddress(walletAddress: address, network: destinationNetwork)
        let cryptoPaymentTokenId = try await coordinator.createCryptoPaymentToken()

        await MainActor.run {
            // intentionally not flipping `isLoading`, since `createOnrampSession` will set it back.
            createOnrampSession(withCryptoPaymentTokenId: cryptoPaymentTokenId, walletAddress: address, coordinator: coordinator)
        }
    }

    private func createOnrampSession(withCryptoPaymentTokenId cryptoPaymentTokenId: String, walletAddress: String, coordinator: CryptoOnrampCoordinator) {
        isLoading.wrappedValue = true

        let request = CreateOnrampSessionRequest(
            paymentToken: cryptoPaymentTokenId,
            sourceAmount: Decimal(string: amountText) ?? 0,
            sourceCurrency: sourceCurrency.rawValue,
            destinationCurrency: destinationCurrency,
            destinationNetwork: destinationNetwork.rawValue,
            destinationCurrencies: [destinationCurrency],
            destinationNetworks: [destinationNetwork.rawValue],
            walletAddress: walletAddress,
            customerIpAddress: "39.131.174.122", // <--- hardcoded for demo
            settlementSpeed: .instant
        )

        Task {
            do {
                let response = try await APIClient.shared.createOnrampSession(requestObject: request)
                print("Onramp session id: \(response.id)")
                await MainActor.run {
                    isLoading.wrappedValue = false
                    if response.requiresWalletOwnershipVerification {
                        pendingWalletOwnershipVerificationCryptoPaymentTokenId = cryptoPaymentTokenId
                        isPresentingWalletOwnershipVerificationAlert = true
                    } else {
                        flowCoordinator.startAfterPrefillPurchase(
                            createOnrampSessionResponse: response,
                            selectedPaymentMethodDescription: "Apple Pay",
                            settlementSpeed: .instant
                        )
                    }
                }
            } catch {
                let fallbackErrorTitle = "Failed to create onramp session"
                var fallbackAlert = Alert(title: fallbackErrorTitle, message: error.localizedDescription)

                if case let .httpError(status, message, code) = error as? APIClient.APIError,
                   status == 400,
                   let code,
                   KYCStepUpRecovery.shouldFetchCustomerInfoForRecovery(forErrorCode: code) {
                    fallbackAlert = Alert(title: fallbackErrorTitle, message: message)

                    do {
                        let customerInfo = try await APIClient.shared.fetchCustomerInfo()
                        let recoveryLevels = KYCStepUpRecovery.recoveryLevels(
                            forErrorCode: code,
                            customerInfo: customerInfo
                        )

                        await MainActor.run {
                            isLoading.wrappedValue = false
                            if let recoveryLevels {
                                // Display the step-up flow.
                                kycRecoveryLevels = recoveryLevels
                            } else {
                                alert = fallbackAlert
                            }
                        }
                    } catch {
                        await MainActor.run {
                            isLoading.wrappedValue = false
                            alert = fallbackAlert
                        }
                    }
                    return
                }

                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = fallbackAlert
                }
            }
        }
    }

    private func verifyWalletOwnershipForPendingCreateOnrampSession() {
        guard let coordinator else { return }

        let address = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let context = WalletOwnershipVerificationContext(
            walletAddress: address,
            network: destinationNetwork,
            isTestMode: !livemode
        )

        WalletOwnershipVerification.requestChallenge(
            context: context,
            coordinator: coordinator,
            isLoading: isLoading,
            alert: $alert
        ) { session in
            walletOwnershipVerificationSession = session
        }
    }

    private func retryPendingCreateOnrampSession() {
        guard let coordinator, let cryptoPaymentTokenId = pendingWalletOwnershipVerificationCryptoPaymentTokenId else {
            return
        }

        pendingWalletOwnershipVerificationCryptoPaymentTokenId = nil
        let address = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        createOnrampSession(withCryptoPaymentTokenId: cryptoPaymentTokenId, walletAddress: address, coordinator: coordinator)
    }

    /// Silently signs up or logs in to the demo merchant backend, since Apple Pay Prefill Mode never shows a
    /// Log In / Sign Up screen for the user to supply a password.
    private func signUpOrLogIn(email: String) async throws {
        do {
            try await APIClient.shared.signUp(email: email, password: Self.demoBackendPassword, livemode: livemode)
        } catch {
            // Assume the failure means an account already exists for this email and fall back to logging in.
            try await APIClient.shared.logIn(email: email, password: Self.demoBackendPassword, livemode: livemode)
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    /// Strips all non-digit characters, as expected by `PhoneNumber.init(number:countryCode:)`.
    var digitsOnly: String {
        filter(\.isNumber)
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        ApplePayPrefillView(
            coordinator: coordinator,
            flowCoordinator: .init(),
            livemode: false,
            alert: .constant(nil)
        )
    }
}
