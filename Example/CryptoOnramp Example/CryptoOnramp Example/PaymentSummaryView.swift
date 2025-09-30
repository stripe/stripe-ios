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
    let onCheckoutSuccess: (_ successMessage: String) -> Void

    @Environment(\.isLoading) private var isLoading

    @State private var authenticationContext = WindowAuthenticationContext()
    @State private var alert: Alert?

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
            }
        })
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.tint)
                    .frame(width: 44, height: 44)

                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .offset(x: 1, y: -1)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Adding")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(onrampSessionResponse.totalText)
                    .font(.title3)
                    .bold()
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            header

            List {
                Section {
                    makeSummaryRow(
                        title: "You Receive",
                        value: onrampSessionResponse.amountToReceiveText
                    )
                    makeSummaryRow(
                        title: "Fees",
                        value: onrampSessionResponse.totalFeesText
                    )
                    makeSummaryRow(
                        title: "Pay With",
                        value: selectedPaymentMethodDescription
                    )
                    makeSummaryRow(
                        title: "Processing Time",
                        value: onrampSessionResponse.processingTimeText
                    )
                    makeSummaryRow(
                        title: "Deposit To",
                        value: onrampSessionResponse.depositToText
                    )
                    makeSummaryRow(
                        title: "Provider",
                        value: "Stripe"
                    )
                } header: {
                    // Collapses the excessive top padding of the list.
                    Spacer(minLength: 8)
                        .listRowInsets(EdgeInsets())
                }
                footer: {
                    Text("By confirming, you agree to the Terms and Conditions and acknowledge the Privacy Policy.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.insetGrouped)
            // Also needed to collapse the excessive top padding of the list.
            .environment(\.defaultMinListHeaderHeight, 0)
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Confirm") {
                checkout()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading.wrappedValue)
            .opacity(isLoading.wrappedValue ? 0.5 : 1)
            .padding()
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
    }

    // MARK: - PaymentSummaryView

    @ViewBuilder
    private func makeSummaryRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

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
                    isLoading.wrappedValue = false
                    switch checkoutResult {
                    case .completed:
                        let amount = onrampSessionResponse.amountToReceiveText
                        let network = onrampSessionResponse.transactionDetails.destinationNetwork.localizedCapitalized
                        onCheckoutSuccess("You’ve added \(amount) to your \(network) wallet.")
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "Checkout failed", message: error.localizedDescription)
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

private extension CreateOnrampSessionResponse {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        // Use local formatting for the number, but assume USD for the currency.
        formatter.locale = Locale.current
        formatter.currencySymbol = "$"
        formatter.currencyCode = "USD"
        return formatter
    }()

    static let currencyFormatterWithoutSymbol: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.currencySymbol = ""
        return formatter
    }()

    var totalText: String {
        let amount = Double(sourceTotalAmount) ?? 0
        return Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    var amountToReceiveText: String {
        let amount = Double(transactionDetails.destinationAmount) ?? 0
        let formattedAmount = Self.currencyFormatterWithoutSymbol.string(from: NSNumber(value: amount)) ?? "$0"
        return "\(formattedAmount) \(transactionDetails.destinationCurrency)"
    }

    var totalFeesText: String {
        let networkFee = Double(transactionDetails.fees.networkFeeAmount) ?? 0
        let transactionFee = Double(transactionDetails.fees.transactionFeeAmount) ?? 0
        let total = networkFee + transactionFee
        return Self.currencyFormatter.string(from: NSNumber(value: total)) ?? "$0"
    }

    var processingTimeText: String {
        if paymentMethod.lowercased().contains("card") {
            "Instant"
        } else {
            "1–3 days"
        }
    }

    var depositToText: String {
        let network = transactionDetails.destinationNetwork.localizedCapitalized
        let address = transactionDetails.walletAddress
        let prefix = String(address.prefix(2))
        let suffix = String(address.suffix(4))
        return "\(network) • \(prefix)••••\(suffix)"
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
                    destinationAmount: "10.000000",
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
                    walletAddress: "0123451234512345123545",
                    walletAddresses: nil
                ),
                uiMode: "headless"
            ),
            selectedPaymentMethodDescription: "Apple Pay",
            onCheckoutSuccess: { _ in }
        )
    }
}
