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
    @State private var livemode: Bool = false
    @State private var alert: Alert?
    @State private var seamlessSignInEmail: String? = APIClient.shared.seamlessSignInEmail

    @AppStorage(DefaultsKeys.seamlessSignInDetails) private var storedSeamlessSignInData: Data?

    @Environment(\.isLoading) private var isLoading

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
            }
        })
    }

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
            ZStack {
                if let seamlessSignInEmail {
                    SeamlessSignInView(
                        coordinator: coordinator,
                        flowCoordinator: flowCoordinator,
                        email: seamlessSignInEmail
                    )
                } else {
                    LogInSignUpView(
                        coordinator: coordinator,
                        flowCoordinator: flowCoordinator,
                        livemode: $livemode
                    )
                }
            }
            .animation(.default, value: seamlessSignInEmail)
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
                                selectedScopes: scopes
                            ) {
                                flowCoordinator.advanceAfterRegistration()
                            }
                        case .kycInfo:
                            KYCInfoView(coordinator: coordinator) {
                                flowCoordinator.advanceAfterKyc()
                            }
                        case .identity:
                            IdentityVerificationView(coordinator: coordinator) {
                                flowCoordinator.advanceAfterIdentity()
                            }
                        case .wallets:
                            WalletSelectionView(
                                coordinator: coordinator
                            ) { wallet in
                                flowCoordinator.advanceAfterWalletSelection(wallet)
                            }
                        case let .payment(wallet):
                            PaymentView(
                                coordinator: coordinator,
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
            APIClient.shared.clearAuthState()
            initializeCoordinator()
        }
        .onChange(of: storedSeamlessSignInData == nil) { didClearSeamlessSignInData in
            // Clear our local seamless sign-in state if the app storage data becomes `nil`.
            // Note that we don’t update it here if it becomes non-nil, as we don’t want this view
            // to transition to display `SeamlessSignInView` while manually authenticating when
            // the credentials initially become available.
            guard didClearSeamlessSignInData else { return }
            seamlessSignInEmail = nil
        }
        .onChange(of: flowCoordinator.pathBinding.wrappedValue.isEmpty) { isEmpty in
            // Update our local storage to remember the authenticated user once we've navigated
            // away from this view. See the comments in the `onChange(of:)` above.
            guard !isEmpty else { return }
            seamlessSignInEmail = APIClient.shared.seamlessSignInEmail
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
                    self.alert = Alert(
                        title: "Failed to initialize CryptoOnrampCoordinator",
                        message: error.localizedDescription
                    )
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
