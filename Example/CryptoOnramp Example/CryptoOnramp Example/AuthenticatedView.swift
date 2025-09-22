//
//  AuthenticatedView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/6/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A view to be displayed after a user has successfully authenticated, with more SDK options to exercise.
struct AuthenticatedView: View {

    /// The coordinator to use for SDK operations like identity verification and KYC info collection.
    let coordinator: CryptoOnrampCoordinator

    let onrampSessionResponse: CreateOnrampSessionResponse

    @State private var errorMessage: String?

    @State private var authenticationContext = WindowAuthenticationContext()

    @State private var checkoutSucceeded = false

    @Environment(\.isLoading) private var isLoading

    private var shouldDisableButtons: Bool {
        isLoading.wrappedValue
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Check Out")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if checkoutSucceeded {
                        Text("Checkout Succeeded!")
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(.green.opacity(0.1))
                            }
                    } else {
                        let details = onrampSessionResponse.transactionDetails

                        VStack(spacing: 8) {
                            // Fees breakdown
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Amount:")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(details.sourceAmount) \(details.sourceCurrency.localizedUppercase)")
                                        .font(.footnote.monospaced())
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Network Fee:")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(details.fees.networkFeeAmount) \(details.sourceCurrency.localizedUppercase)")
                                        .font(.footnote.monospaced())
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Transaction Fee:")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(details.fees.transactionFeeAmount) \(details.sourceCurrency.localizedUppercase)")
                                        .font(.footnote.monospaced())
                                        .foregroundColor(.secondary)
                                }

                                Divider()

                                HStack {
                                    Text("Total:")
                                        .font(.footnote)
                                        .bold()
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(onrampSessionResponse.sourceTotalAmount) \(details.sourceCurrency.localizedUppercase)")
                                        .font(.footnote.monospaced())
                                        .bold()
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.vertical, 8)

                            Button("Check Out | \(onrampSessionResponse.sourceTotalAmount) \(details.sourceCurrency.localizedUppercase)") {
                                checkout()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(shouldDisableButtons)
                            .opacity(shouldDisableButtons ? 0.5 : 1)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Account")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button("Log out") {
                            logOut()
                        }
                        .font(.body)
                        .foregroundColor(.red)
                        .disabled(shouldDisableButtons)
                        .opacity(shouldDisableButtons ? 0.5 : 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

            }
            .padding()
        }
        .navigationTitle("Authenticated")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkout() {
        isLoading.wrappedValue = true
        errorMessage = nil

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
                        checkoutSucceeded = true
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                    isLoading.wrappedValue = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Checkout failed: \(error.localizedDescription)"
                    isLoading.wrappedValue = false
                }
            }
        }
    }

    private func logOut() {
        guard let viewController = UIApplication.shared.findTopNavigationController() else {
            errorMessage = "Unable to find view controller to navigate from."
            return
        }

        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                try await coordinator.logOut()
                await MainActor.run {
                    isLoading.wrappedValue = false
                    viewController.popToRootViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Log out failed: \(error.localizedDescription)"
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
        AuthenticatedView(
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
            )
        )
    }
}
