//
//  AuthenticatedView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/6/25.
//

import PassKit
import SwiftUI

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A view to be displayed after a user has successfully authenticated, with more SDK options to exercise.
struct AuthenticatedView: View {

    /// The coordinator to use for SDK operations like identity verification and KYC info collection.
    let coordinator: CryptoOnrampCoordinator

    /// The customer id of the authenticated user.
    let customerId: String

    @State private var errorMessage: String?
    @State private var isIdentityVerificationComplete = false
    @State private var showKYCView = false
    @State private var showAttachWalletSheet = false
    @State private var selectedPaymentMethod: PaymentMethodPreview?
    @State private var cryptoPaymentToken: String?

    @Environment(\.isLoading) private var isLoading

    private var shouldDisableButtons: Bool {
        isLoading.wrappedValue
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Customer Information")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    // Identity and KYC actions within the section
                    if isIdentityVerificationComplete {
                        Text("Identity Verification Complete")
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(.green.opacity(0.1))
                            }
                    } else {
                        Button("Verify Identity") {
                            verifyIdentity()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(shouldDisableButtons)
                        .opacity(shouldDisableButtons ? 0.5 : 1)
                    }

                    Button("Submit KYC Information") {
                        showKYCView = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(shouldDisableButtons)
                    .opacity(shouldDisableButtons ? 0.5 : 1)

                    Button("Attach Wallet Address") {
                        showAttachWalletSheet = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(shouldDisableButtons)
                    .opacity(shouldDisableButtons ? 0.5 : 1)

                    HStack(spacing: 4) {
                        Text("Customer ID:")
                            .font(.footnote)
                            .bold()
                            .foregroundColor(.secondary)
                        Text(customerId)
                            .font(.footnote.monospaced())
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Check Out")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if let selectedPaymentMethod {
                        HStack {
                            Spacer()
                            PaymentMethodCardView(preview: selectedPaymentMethod)
                            Spacer()
                        }

                        Button("Create crypto payment token") {
                            createCryptoPaymentToken()
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        if let cryptoPaymentToken {
                            HStack(spacing: 4) {
                                Text("Crypto payment token:")
                                    .font(.footnote)
                                    .bold()
                                    .foregroundColor(.secondary)
                                Text(cryptoPaymentToken)
                                    .font(.footnote.monospaced())
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            // Note: Apple Pay does not require iOS 16, but the native SwiftUI
                            // `PayWithApplePayButton` does, which we're using in this example.
                            // For earlier OS versions, use `PKPaymentButton` in UIKit, optionally
                            // wrapping it in a `UIViewRepresentable` for SwiftUI.
                            if #available(iOS 16.0, *), StripeAPI.deviceSupportsApplePay() {
                                PayWithApplePayButton(.plain) {
                                    presentApplePay()
                                }
                                .frame(height: 52)
                                .cornerRadius(8)
                                .disabled(shouldDisableButtons)
                                .opacity(shouldDisableButtons ? 0.5 : 1)
                            }

                            Button("Debit or Credit Card") {
                                presentPaymentMethodSelector(for: .card)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(shouldDisableButtons)
                            .opacity(shouldDisableButtons ? 0.5 : 1)

                            Button("Bank Account") {
                                presentPaymentMethodSelector(for: .bankAccount)
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

                HiddenNavigationLink(
                    destination: KYCInfoView(coordinator: coordinator),
                    isActive: $showKYCView
                )
            }
            .padding()
        }
        .navigationTitle("Authenticated")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAttachWalletSheet) {
            AttachWalletAddressView(coordinator: coordinator)
        }
    }

    private func verifyIdentity() {
        guard let viewController = UIApplication.shared.findTopNavigationController() else {
            errorMessage = "Unable to find view controller to present from."
            return
        }

        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                let result = try await coordinator.promptForIdentityVerification(from: viewController)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    switch result {
                    case .completed:
                        isIdentityVerificationComplete = true
                    case .canceled:
                        // User canceled verification, no action needed.
                        break
                    @unknown default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Identity verification failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func presentPaymentMethodSelector(for type: PaymentMethodType) {
        guard let viewController = UIApplication.shared.findTopNavigationController() else {
            errorMessage = "Unable to find view controller to present from."
            return
        }

        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                let preview = try await coordinator.collectPaymentMethod(type: type, from: viewController)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    selectedPaymentMethod = preview
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Payment method selection failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func presentApplePay() {
        guard let viewController = UIApplication.shared.findTopNavigationController() else {
            errorMessage = "Unable to find view controller to present from."
            return
        }

        let request = StripeAPI.paymentRequest(withMerchantIdentifier: "com.example.merchant", country: "US", currency: "USD")
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Example", amount: NSDecimalNumber(string: "1.00"))
        ]

        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                let result = try await coordinator.collectPaymentMethod(type: .applePay(paymentRequest: request), from: viewController)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    selectedPaymentMethod = result
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Apple Pay failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func createCryptoPaymentToken() {
        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                let token = try await coordinator.createCryptoPaymentToken()
                await MainActor.run {
                    isLoading.wrappedValue = false
                    cryptoPaymentToken = token
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Create crypto payment token failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        AuthenticatedView(
            coordinator: coordinator,
            customerId: "cus_example123456789"
        )
    }
}
