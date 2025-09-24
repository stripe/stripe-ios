//
//  PaymentSummaryView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/24/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

@_spi(STP)
import StripePayments

/// A view used to display a payment summary, from which the user can complete checkout.
struct PaymentSummaryView: View {
    
    /// The coordinator to use for completing checkout.
    let coordinator: CryptoOnrampCoordinator

    /// The response from creating an onramp session in a prior step.
    let onrampSessionResponse: CreateOnrampSessionResponse

    /// A description of the payment method selected in a prior step.
    let selectedPaymentMethodDescription: String

    /// Called upon completing checkout successfully.
    let onCheckoutSuccess: () -> Void

    @Environment(\.isLoading) private var isLoading

    @State private var authenticationContext = WindowAuthenticationContext()

    // MARK: - View

    var body: some View {
        EmptyView()
    }

    // MARK: - PaymentSummaryView

    private func checkout() {
        isLoading.wrappedValue = true

        Task {
            do {
                let checkoutResult = try await coordinator.performCheckout(
                    onrampSessionId: onrampSessionResponse.id,
                    authenticationContext: authenticationContext
                ) { onrampSessionId in
                    let result = try await APIClient.shared.checkout(onrampSessionId: onrampSessionId)
                    return  result.clientSecret
                }

                await MainActor.run {
                    switch checkoutResult {
                    case .completed:
                        onCheckoutSuccess()
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                    isLoading.wrappedValue = false
                }
            } catch {
                await MainActor.run {
                    // TODO: display alert
                    // errorMessage = "Checkout failed: \(error.localizedDescription)"
                    isLoading.wrappedValue = false
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
    PreviewWrapperView { coordinator in
        PaymentSummaryView(
            coordinator: coordinator,
            onrampSessionResponse: .init(
                id: "0",
                object: "",
                clientSecret: "abc",
                created: 0,
                cryptoCustomerId: "crc_1234",
                finishUrl: nil,
                isApplePay: false,
                kycDetailsProvided: true,
                livemode: false,
                metadata: nil,
                paymentMethod: "Card",
                preferredPaymentMethod: nil,
                preferredRegion: nil,
                redirectUrl: "",
                skipQuoteScreen: false,
                sourceTotalAmount: "10.61",
                status: "",
                transactionDetails: .init(
                    destinationCurrency: "usdc",
                    destinationAmount: "10.00",
                    destinationNetwork: "solana",
                    fees: .init(
                        networkFeeAmount: "0.01",
                        transactionFeeAmount: "0.60"
                    ),
                    lastError: nil,
                    lockWalletAddress: false,
                    quoteExpiration: Date(),
                    sourceCurrency: "usd",
                    sourceAmount: "10.00",
                    destinationCurrencies: [],
                    destinationNetworks: [],
                    transactionId: nil,
                    transactionLimit: 74517,
                    walletAddress: "",
                    walletAddresses: nil
                ),
                uiMode: "headless"
            ),
            selectedPaymentMethodDescription: "Apple Pay",
            onCheckoutSuccess: {}
        )
    }
}
