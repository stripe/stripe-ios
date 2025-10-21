//
//  CryptoOnrampExampleView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/24/25.
//

import StripeCore
import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// The main content view of the example CryptoOnramp app.
struct CryptoOnrampExampleView: View {
    @StateObject private var flowCoordinator = CryptoOnrampFlowCoordinator()

    @State private var coordinator: CryptoOnrampCoordinator?
    @State private var errorMessage: String?
    @State private var livemode: Bool = false

    @Environment(\.isLoading) private var isLoading

    private var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - View

    var body: some View {
        NavigationStack(path: flowCoordinator.pathBinding) {
            LogInSignUpView(
                coordinator: coordinator,
                flowCoordinator: flowCoordinator,
                livemode: $livemode
            )
            .navigationTitle("CryptoOnramp Example")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CryptoOnrampFlowCoordinator.Route.self) { route in
                if let coordinator {
                    ZStack {
                        switch route {
                        case let .registration(email, scopes):
                            RegistrationView(
                                coordinator: coordinator,
                                email: email,
                                selectedScopes: scopes,
                                livemode: livemode
                            ) { customerId in
                                flowCoordinator.advanceAfterRegistration(customerId: customerId)
                            }
                        case .kycInfo:
                            KYCInfoView(coordinator: coordinator) {
                                flowCoordinator.advanceAfterKyc()
                            }
                        case .identity:
                            IdentityVerificationView(coordinator: coordinator) {
                                flowCoordinator.advanceAfterIdentity()
                            }
                        case let .wallets(customerId):
                            WalletSelectionView(
                                coordinator: coordinator,
                                customerId: customerId
                            ) { wallet in
                                flowCoordinator.advanceAfterWalletSelection(wallet)
                            }
                        case let .payment(customerId, wallet):
                            PaymentView(
                                coordinator: coordinator,
                                customerId: customerId,
                                wallet: wallet
                            ) { response, selectedPaymentMethodDescription in
                                flowCoordinator.advanceAfterPayment(
                                    createOnrampSessionResponse: response,
                                    selectedPaymentMethodDescription: selectedPaymentMethodDescription
                                )
                            }
                        case let .paymentSummary(createOnrampSessionResponse, selectedPaymentMethodDescription):
                            PaymentSummaryView(
                                coordinator: coordinator,
                                onrampSessionResponse: createOnrampSessionResponse,
                                selectedPaymentMethodDescription: selectedPaymentMethodDescription
                            ) { message in
                                flowCoordinator.advanceAfterPaymentSummary(successfulCheckoutMessage: message)
                            }
                        case let .checkoutSuccess(message):
                            CheckoutSuccessView(message: message)
                        }
                    }
                    .navigationBarBackButtonHidden(!route.allowsBackNavigation)
                    .authenticatedUserToolbar(
                        isShown: route.showsAuthenticatedUserToolbarItem,
                        coordinator: coordinator,
                        flowCoordinator: flowCoordinator
                    )
                }
            }
        }
        .onAppear {
            flowCoordinator.isLoading = isLoading

            // Force livemode to false on simulator
            if isRunningOnSimulator {
                livemode = false
            }

            guard coordinator == nil else {
                return
            }
            initializeCoordinator()
        }
        .onChange(of: livemode) { _ in
            coordinator = nil
            errorMessage = nil
            initializeCoordinator()
        }
    }

    private func initializeCoordinator() {
        STPAPIClient.shared.setUpPublishableKey(livemode: livemode)

        isLoading.wrappedValue = true
        Task {
            do {
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
                let coordinator = try await CryptoOnrampCoordinator.create(appearance: appearance)

                await MainActor.run {
                    self.coordinator = coordinator
                    self.isLoading.wrappedValue = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading.wrappedValue = false
                    self.errorMessage = "Failed to initialize CryptoOnrampCoordinator: \(error.localizedDescription)"
                }
            }
        }
    }
}

private extension CryptoOnrampFlowCoordinator {
    var pathBinding: Binding<[Route]> {
        Binding(get: { self.path }, set: { self.path = $0 })
    }
}

#Preview {
    CryptoOnrampExampleView()
}
