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
    @State private var selectedPaymentMethod: PaymentMethodPreview?

    @Environment(\.isLoading) private var isLoading

    private var shouldDisableButtons: Bool {
        isLoading.wrappedValue
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                if let selectedPaymentMethod {
                    PaymentMethodCardView(preview: selectedPaymentMethod)
                } else {
                    Button("Select Payment Method") {
                        presentPaymentMethodSelector()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(shouldDisableButtons)
                    .opacity(shouldDisableButtons ? 0.5 : 1)

                    if #available(iOS 16.0, *), StripeAPI.deviceSupportsApplePay() {
                        PayWithApplePayButton(.plain) {
                            presentApplePay()
                        }
                        .frame(height: 45)
                        .frame(maxWidth: .infinity)
                        .disabled(shouldDisableButtons)
                        .opacity(shouldDisableButtons ? 0.5 : 1)
                    }
                }

                VStack(spacing: 8) {
                    Text("Customer ID")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Text(customerId)
                        .font(.subheadline.monospaced())
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
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

    private func presentPaymentMethodSelector() {
        guard let viewController = UIApplication.shared.findTopNavigationController() else {
            errorMessage = "Unable to find view controller to present from."
            return
        }

        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            let preview = await coordinator.collectPaymentMethod(from: viewController)
            await MainActor.run {
                isLoading.wrappedValue = false
                selectedPaymentMethod = preview
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
                let result = try await coordinator.selectApplePay(using: request, from: viewController)
                await MainActor.run {
                    isLoading.wrappedValue = false

                    switch result {
                    case .success:
                        self.selectedPaymentMethod = PaymentMethodPreview(
                            icon: UIImage(systemName: "apple.logo")?.withRenderingMode(.alwaysTemplate) ?? .init(),
                            label: "Apple Pay",
                            sublabel: nil
                        )
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Apple Pay failed: \(error.localizedDescription)"
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
