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
    @State private var email: String = ""
    @State private var selectedScopes: Set<OAuthScopes> = Set(OAuthScopes.requiredScopes)
    @State private var linkAuthIntentId: String?
    @State private var livemode: Bool = false

    @Environment(\.isLoading) private var isLoading
    @FocusState private var isEmailFieldFocused: Bool

    private var isNextButtonDisabled: Bool {
        isLoading.wrappedValue || email.isEmpty || coordinator == nil
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
            linkAuthIntentId = nil
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

    private func lookupConsumerAndContinue() {
        guard let coordinator else { return }
        isLoading.wrappedValue = true
        Task {
            do {
                let lookupResult = try await coordinator.hasLinkAccount(with: email)
                let laiId: String?
                if lookupResult {
                    // Get Link Auth Intent ID from the demo merchant backend.
                    let response = try await APIClient.shared.authenticateUser(
                        with: email,
                        oauthScopes: Array(selectedScopes),
                        livemode: livemode
                    )
                    laiId = response.data.id
                    print( "Successfully got Link Auth Intent ID from demo backend. Id: \(laiId!)")
                } else {
                    laiId = nil
                }

                await MainActor.run {
                    errorMessage = nil
                    isLoading.wrappedValue = false
                    linkAuthIntentId = laiId

                    if lookupResult {
                        presentVerification(using: coordinator)
                    } else {
                        flowCoordinator.startForNewUser(email: email, selectedScopes: Array(selectedScopes))
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Customer lookup failed. Ensure the email address is properly formatted. (Underlying error: \(error.localizedDescription))"
                }
            }
        }
    }

    private func presentVerification(using coordinator: CryptoOnrampCoordinator) {
        guard let linkAuthIntentId = linkAuthIntentId else {
            errorMessage = "No Link Auth Intent ID available for authorization."
            return
        }

        if let viewController = UIApplication.shared.findTopNavigationController() {
            Task {
                do {
                    let result = try await coordinator.authorize(linkAuthIntentId: linkAuthIntentId, from: viewController)
                    switch result {
                    case .consented(let customerId):
                        await MainActor.run {
                            flowCoordinator.startForExistingUser(customerId: customerId)
                        }
                    case .denied:
                        await MainActor.run {
                            errorMessage = "Authorization was denied."
                        }
                    case .canceled:
                        // do nothing, authorization canceled.
                        break
                    @unknown default:
                        // do nothing, authorization canceled.
                        break
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            errorMessage = "Unable to find view controller to present from."
        }
    }
}

struct OAuthScopeSelector: View {
    @Binding var selectedScopes: Set<OAuthScopes>
    let onOnrampScopesSelected: () -> Void
    let onAllScopesSelected: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Button("Required") {
                            onOnrampScopesSelected()
                        }

                        Button("All") {
                            onAllScopesSelected()
                        }

                        Spacer()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    VStack(spacing: 8) {
                        ForEach(OAuthScopes.allCases, id: \.self) { scope in
                            Button(action: {
                                if selectedScopes.contains(scope) {
                                    selectedScopes.remove(scope)
                                } else {
                                    selectedScopes.insert(scope)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedScopes.contains(scope) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedScopes.contains(scope) ? .blue : .gray)
                                        .font(.system(size: 14))

                                    Text(scope.rawValue)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedScopes.contains(scope) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding([.bottom, .horizontal])
            }
            .navigationTitle("OAuth Scopes")
            .navigationBarTitleDisplayMode(.inline)
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
