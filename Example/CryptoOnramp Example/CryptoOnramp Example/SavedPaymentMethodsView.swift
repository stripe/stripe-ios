//
//  SavedPaymentMethodsView.swift
//  CryptoOnramp Example
//
//  Created by Mat Schmid on 9/22/25.
//

import PassKit
import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

@_spi(STP)
import StripeApplePay

@_spi(STP)
import StripePaymentSheet

@_spi(STP)
import StripePayments

/// A view that displays saved payment methods (crypto wallets) and Apple Pay option for checkout.
struct SavedPaymentMethodsView: View {
    /// The crypto customer ID to fetch wallets for.
    let cryptoCustomerId: String

    /// The email address used for authentication.
    let email: String

    /// The OAuth scopes for authentication.
    let oauthScopes: [OAuthScopes]

    /// Whether the app is in livemode.
    let livemode: Bool

    @State private var coordinator: CryptoOnrampCoordinator?
    @State private var errorMessage: String?
    @State private var selectedPaymentMethod: PaymentMethodOption?
    @State private var isApplePayAvailable = false
    @State private var onrampSessionResponse: CreateOnrampSessionResponse?
    @State private var checkoutSucceeded = false
    @State private var authenticationContext = WindowAuthenticationContext()

    // Demo values for checkout (in a real app, these would be user inputs)
    private let sourceAmount: Decimal = 50.0
    private let sourceCurrency = "usd"
    private let destinationCurrency = "eth"
    private let destinationNetwork = "ethereum"
    private let walletAddress = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e" // Demo Ethereum wallet address

    @Environment(\.isLoading) private var isLoading

    private var isCheckoutButtonDisabled: Bool {
        isLoading.wrappedValue || selectedPaymentMethod == nil || coordinator == nil
    }

    /// Represents a crypto payment token for saved payment methods.
    struct CryptoPaymentToken: Identifiable, Hashable {
        let id: String
        let displayName: String
        let requiresAuthentication: Bool

        var displaySubtitle: String {
            requiresAuthentication ? "Requires 3DS authentication" : "No 3DS required"
        }
    }

    /// Represents a payment method option (either crypto payment token or Apple Pay).
    enum PaymentMethodOption: Identifiable, Hashable {
        case cryptoPaymentToken(CryptoPaymentToken)
        case applePay

        var id: String {
            switch self {
            case .cryptoPaymentToken(let token):
                return token.id
            case .applePay:
                return "apple_pay"
            }
        }

        var displayTitle: String {
            switch self {
            case .cryptoPaymentToken(let token):
                return token.displayName
            case .applePay:
                return "Apple Pay"
            }
        }

        var displaySubtitle: String {
            switch self {
            case .cryptoPaymentToken(let token):
                return token.displaySubtitle
            case .applePay:
                return "Pay with Touch ID or Face ID"
            }
        }
    }

    /// Hardcoded crypto payment tokens for demonstration.
    private var availablePaymentTokens: [CryptoPaymentToken] {
        [
            CryptoPaymentToken(
                id: "cpt_1SAE38DyaLrjkeNaOngc8NMQ",
                displayName: "Saved Payment Method",
                requiresAuthentication: false
            ),
            CryptoPaymentToken(
                id: "cpt_1SAE2hDyaLrjkeNaJdwLu6m4",
                displayName: "Saved Payment Method (3DS)",
                requiresAuthentication: true
            ),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Image(systemName: "creditcard")
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Color(.systemGroupedBackground)
                            .cornerRadius(16)
                    }

                VStack(spacing: 6) {
                    Text("Select Payment Method")
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Choose a saved payment method or use Apple Pay to fund your crypto purchase.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                // Payment method options
                VStack(spacing: 12) {
                    // Saved crypto payment tokens
                    ForEach(availablePaymentTokens) { token in
                        makePaymentMethodButton(for: .cryptoPaymentToken(token))
                    }

                    // Apple Pay
                    if isApplePayAvailable {
                        makePaymentMethodButton(for: .applePay)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Checkout") {
                performCheckout()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isCheckoutButtonDisabled)
            .opacity(isCheckoutButtonDisabled ? 0.5 : 1)
            .padding()
        }
        .onAppear {
            initializeCoordinatorAndFetchData()
        }
        .alert("Checkout Successful!", isPresented: $checkoutSucceeded) {
            Button("OK") {
                checkoutSucceeded = false
            }
        } message: {
            Text("Your crypto purchase was completed successfully.")
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func makePaymentMethodButton(for option: PaymentMethodOption) -> some View {
        Button {
            selectedPaymentMethod = option
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayTitle)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(option.displaySubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if selectedPaymentMethod == option {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedPaymentMethod == option ? Color.accentColor.opacity(0.12) : Color(.systemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private func initializeCoordinatorAndFetchData() {
        guard coordinator == nil else {
            return
        }

        isLoading.wrappedValue = true
        Task {
            do {
                // First authenticate with the demo backend to get auth token
                _ = try await APIClient.shared.authenticateUser(
                    with: email,
                    oauthScopes: oauthScopes,
                    livemode: livemode
                )
                APIClient.shared.setAuthToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdXRoSW50ZW50SWQiOiJsYWlfMVNBSEk1SE1hRHN2ZVdxMGJJdHpkOUhFIiwidXNlcklkIjoiOTNiZmZkMzc3ZTBjYmI2NDFiOGM1MjhhM2E2YTA0OTgzODZiMmY2NjE0NGFjZmFmNjQ3NDhkMzRiZTk5NGRlMiIsImxpdmVtb2RlIjpmYWxzZSwiaWF0IjoxNzU4NTc2NTM3LCJleHAiOjE3NTg1ODAxMzd9.b6N8T0m5higmbIkDisPg7UcmSXFBzUvi0xs_ZfQVwcY")

                let lavenderColor = UIColor(
                    red: 171/255.0,
                    green: 159/255.0,
                    blue: 242/255.0,
                    alpha: 1.0
                )
                let appearance = LinkAppearance(
                    colors: .init(primary: lavenderColor, selectedBorder: .label),
                    primaryButton: .init(cornerRadius: 16, height: 56),
                    style: .automatic,
                    reduceLinkBranding: true
                )

                // Create coordinator with crypto customer ID
                let coordinator = try await CryptoOnrampCoordinator.create(
                    appearance: appearance,
                    cryptoCustomerID: cryptoCustomerId
                )

                await MainActor.run {
                    self.coordinator = coordinator
                    self.isApplePayAvailable = PKPaymentAuthorizationController.canMakePayments()
                    self.isLoading.wrappedValue = false

                    // Auto-select first available option
                    if selectedPaymentMethod == nil {
                        if !availablePaymentTokens.isEmpty {
                            selectedPaymentMethod = .cryptoPaymentToken(availablePaymentTokens[0])
                        } else if isApplePayAvailable {
                            selectedPaymentMethod = .applePay
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading.wrappedValue = false
                    self.errorMessage = "Failed to initialize: \(error.localizedDescription)"
                }
            }
        }
    }

    private func performCheckout() {
        guard let selectedPaymentMethod else {
            errorMessage = "Please select a payment method."
            return
        }

        switch selectedPaymentMethod {
        case .cryptoPaymentToken(let token):
            // Use the existing crypto payment token directly
            createOnrampSession(withCryptoPaymentToken: token.id)
        case .applePay:
            // First collect Apple Pay payment method, then create crypto payment token
            collectApplePayAndCheckout()
        }
    }

    private func collectApplePayAndCheckout() {
        guard let coordinator = coordinator else {
            errorMessage = "Coordinator not initialized."
            return
        }

        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                // Create Apple Pay payment request
                let paymentRequest = PKPaymentRequest()
                paymentRequest.merchantIdentifier = "merchant.com.stripe.CryptoOnramp-Example"
                paymentRequest.supportedNetworks = [.visa, .masterCard, .amex, .discover]
                paymentRequest.merchantCapabilities = .threeDSecure
                paymentRequest.countryCode = "US"
                paymentRequest.currencyCode = sourceCurrency.uppercased()

                let paymentSummaryItem = PKPaymentSummaryItem(
                    label: "Crypto Purchase",
                    amount: NSDecimalNumber(decimal: sourceAmount),
                    type: .final
                )
                paymentRequest.paymentSummaryItems = [paymentSummaryItem]

                // Get view controller for presentation
                guard let viewController = UIApplication.shared.findTopNavigationController() else {
                    throw CryptoOnrampCoordinator.Error.missingCryptoCustomerID
                }

                // Collect Apple Pay payment method
                let paymentMethodType = PaymentMethodType.applePay(paymentRequest: paymentRequest)
                guard try await coordinator.collectPaymentMethod(
                    type: paymentMethodType,
                    from: viewController
                ) != nil else {
                    // User canceled Apple Pay
                    await MainActor.run {
                        isLoading.wrappedValue = false
                    }
                    return
                }

                // Create crypto payment token from Apple Pay payment method
                let cryptoPaymentToken = try await coordinator.createCryptoPaymentToken()

                await MainActor.run {
                    // Now create onramp session with the crypto payment token
                    createOnrampSession(withCryptoPaymentToken: cryptoPaymentToken)
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Apple Pay collection failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func createOnrampSession(withCryptoPaymentToken cryptoPaymentToken: String) {
        isLoading.wrappedValue = true
        errorMessage = nil

        let request = CreateOnrampSessionRequest(
            paymentToken: cryptoPaymentToken,
            sourceAmount: sourceAmount,
            sourceCurrency: sourceCurrency,
            destinationCurrency: destinationCurrency,
            destinationNetwork: destinationNetwork,
            walletAddress: walletAddress,
            cryptoCustomerId: cryptoCustomerId,
            customerIpAddress: "39.131.174.122" // Hardcoded for demo
        )

        Task {
            do {
                let response = try await APIClient.shared.createOnrampSession(requestObject: request)
                await MainActor.run {
                    onrampSessionResponse = response
                    checkout(with: response, paymentToken: cryptoPaymentToken)
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Create onramp session failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func checkout(
        with onrampSessionResponse: CreateOnrampSessionResponse,
        paymentToken: String
    ) {
        guard let coordinator = coordinator else {
            errorMessage = "Coordinator not initialized."
            isLoading.wrappedValue = false
            return
        }

        Task {
            do {
                let checkoutResult = try await coordinator.performCheckout(
                    onrampSessionId: onrampSessionResponse.id,
                    authenticationContext: authenticationContext
                ) { onrampSessionId in
                    let result = try await APIClient.shared.checkout(onrampSessionId: onrampSessionId)
                    return result.clientSecret
                }

                await MainActor.run {
                    isLoading.wrappedValue = false
                    switch checkoutResult {
                    case .completed:
                        checkoutSucceeded = true
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Checkout failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

private class WindowAuthenticationContext: NSObject, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        UIApplication.shared.findTopNavigationController() ?? UIViewController()
    }
}

#Preview {
    NavigationStack {
        SavedPaymentMethodsView(
            cryptoCustomerId: "cus_example",
            email: "test@example.com",
            oauthScopes: OAuthScopes.requiredScopes,
            livemode: false
        )
    }
}
