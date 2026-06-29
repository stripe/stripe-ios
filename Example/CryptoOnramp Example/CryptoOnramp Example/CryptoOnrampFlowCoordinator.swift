//
//  CryptoOnrampFlowCoordinator.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/10/25.
//

import Foundation
import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// Helps to coordinate stepping through a multi-step flow to collect only necessary data based on known account information.
@MainActor
final class CryptoOnrampFlowCoordinator: ObservableObject {

    /// Represents the possible steps in the flow.
    enum Route: Hashable {
        case registration(email: String, oAuthScopes: [OAuthScopes])
        case kycInfo(collectionMode: KYCInfoView.CollectionMode)
        case complianceIdentifiers(requirements: ComplianceIdentifierRequirements)
        case userAttestation
        case identity
        case wallets
        case payment(wallet: CustomerWalletsResponse.Wallet)
        case paymentSummary(createOnrampSessionResponse: CreateOnrampSessionResponse, selectedPaymentMethodDescription: String, settlementSpeed: CreateOnrampSessionRequest.SettlementSpeed)
        case checkoutSuccess(message: String)
    }

    /// Indicates whether the global loading interface should be shown.
    var isLoading: Binding<Bool>?

    /// The current navigation path, intended to be used with `NavigationStack`.
    @Published var path: [Route] = []

    private(set) var selectedWallet: CustomerWalletsResponse.Wallet?
    private var kycLevel: KYCLevel = .none
    private var isKycVerified = false
    private var isIdDocumentVerified = false
    private var isEUCustomer = false
    private var hasSubmittedIdentifiers = false
    private var hasAcceptedUserAttestation = false
    private var identifierRequirements: ComplianceIdentifierRequirements?
    private var kycInfoCollectionMode: KYCInfoView.CollectionMode = .original
    private var createOnrampSessionResponse: CreateOnrampSessionResponse?
    private var selectedPaymentMethodDescription: String?
    private var settlementSpeed: CreateOnrampSessionRequest.SettlementSpeed?
    private var successfulCheckoutMessage: String?

    /// Creates a new `CryptoOnrampFlowCoordinator`.
    init() {

    }

    /// Begins the flow for an existing user.
    /// - Parameters:
    ///   - kycInfoCollectionMode: The KYC info screen collection mode to use if KYC needs to be collected.
    ///   - coordinator: The CryptoOnramp coordinator to use when retrieving customer compliance requirements.
    func startForExistingUser(
        kycInfoCollectionMode: KYCInfoView.CollectionMode = .original,
        coordinator: CryptoOnrampCoordinator
    ) {
        resetInternalState()
        self.kycInfoCollectionMode = kycInfoCollectionMode
        Task {
            await refreshCustomerInfoAndPushNext(coordinator: coordinator)
        }
    }

    /// Begins the flow for a new, yet-to-be registered user.
    /// - Parameters:
    ///   - email: The user’s email.
    ///   - selectedScopes: The OAuth scopes the user selected.
    ///   - kycInfoCollectionMode: The KYC info screen collection mode to use if KYC needs to be collected.
    func startForNewUser(
        email: String,
        selectedScopes: [OAuthScopes],
        kycInfoCollectionMode: KYCInfoView.CollectionMode = .original
    ) {
        resetInternalState()
        self.kycInfoCollectionMode = kycInfoCollectionMode
        path = [.registration(email: email, oAuthScopes: selectedScopes)]
    }

    /// Advances to the next step of the flow post-registration.
    /// - Parameter coordinator: The CryptoOnramp coordinator to use when refreshing customer state and retrieving compliance requirements.
    func advanceAfterRegistration(coordinator: CryptoOnrampCoordinator) {
        Task {
            await refreshCustomerInfoAndPushNext(coordinator: coordinator)
        }
    }

    /// Advances to the next step of the flow post-KYC info collection.
    /// - Parameters:
    ///   - collectedKYCLevel: The KYC level collected by the KYC info view.
    ///   - isEUCustomer: Whether the user's region is EU.
    ///   - coordinator: The CryptoOnramp coordinator to use when retrieving compliance identifier requirements.
    func advanceAfterKyc(
        collectedKYCLevel: KYCLevel,
        isEUCustomer: Bool,
        coordinator: CryptoOnrampCoordinator
    ) {
        kycLevel = collectedKYCLevel
        self.isEUCustomer = isEUCustomer
        hasSubmittedIdentifiers = false
        hasAcceptedUserAttestation = false
        identifierRequirements = nil
        if kycInfoCollectionMode == .original {
            isKycVerified = true
        }
        if isEUCustomer {
            Task {
                await retrieveIdentifierRequirementsAndAdvance(coordinator: coordinator)
            }
        } else {
            advanceToNextStep()
        }
    }

    /// Advances after submitting required compliance identifiers.
    func advanceAfterIdentifiers() {
        hasSubmittedIdentifiers = true
        advanceToNextStep()
    }

    /// Advances after accepting the user attestation.
    func advanceAfterUserAttestation() {
        hasAcceptedUserAttestation = true
        advanceToNextStep()
    }

    /// Advances to the next step in the flow post-identity verification.
    func advanceAfterIdentity() {
        isIdDocumentVerified = true
        kycLevel = .level2
        advanceToNextStep()
    }

    /// Advances to the next step after selecting a wallet.
    /// - Parameter wallet: The wallet to fund in the next steps.
    func advanceAfterWalletSelection(_ wallet: CustomerWalletsResponse.Wallet) {
        selectedWallet = wallet
        advanceToNextStep()
    }

    /// Advances after configuring payment.
    /// - Parameters:
    ///   - createOnrampSessionResponse: The onramp session that was created for checking out.
    ///   - selectedPaymentMethodDescription: A description of the selected payment used to start the onramp session.
    ///   - settlementSpeed: When a bank account was used, this specifies the speed at which funds will be delivered. If a bank account was not used, the value should always be `.instant`.
    func advanceAfterPayment(createOnrampSessionResponse: CreateOnrampSessionResponse, selectedPaymentMethodDescription: String, settlementSpeed: CreateOnrampSessionRequest.SettlementSpeed) {
        self.createOnrampSessionResponse = createOnrampSessionResponse
        self.selectedPaymentMethodDescription = selectedPaymentMethodDescription
        self.settlementSpeed = settlementSpeed
        advanceToNextStep()
    }

    /// Advances after the payment summary step, which indicates a successful checkout.
    /// - Parameter successfulCheckoutMessage: The message to display on the final step.
    func advanceAfterPaymentSummary(successfulCheckoutMessage: String) {
        self.successfulCheckoutMessage = successfulCheckoutMessage
        advanceToNextStep()
    }

    private func refreshCustomerInfoAndPushNext(coordinator: CryptoOnrampCoordinator) async {
        isLoading?.wrappedValue = true
        defer { isLoading?.wrappedValue = false }
        do {
            let info = try await APIClient.shared.fetchCustomerInfo()
            kycLevel = info.kycLevel
            isKycVerified = info.isKycVerified
            isIdDocumentVerified = info.isIdDocumentVerified
            isEUCustomer = info.isEUCustomer
            hasSubmittedIdentifiers = info.hasSubmittedIdentifiers
            hasAcceptedUserAttestation = info.hasAcceptedUserAttestation
            if shouldRetrieveIdentifierRequirements && hasCollectedInitialKYCInfo {
                setIdentifierRequirements(try await coordinator.retrieveMissingIdentifiers())
            }
            advanceToNextStep()
        } catch {
            presentAlert(
                title: "Unable to determine KYC and identity verification statuses",
                message: "Please ensure you have the required OAuth scopes selected and try again.\n\n\(error.localizedDescription)"
            )
        }
    }

    private var shouldRetrieveIdentifierRequirements: Bool {
        isEUCustomer && !hasSubmittedIdentifiers && identifierRequirements == nil
    }

    private var hasCollectedInitialKYCInfo: Bool {
        if kycInfoCollectionMode == .original {
            return isKycVerified
        }

        return kycLevel.includesLevel0
    }

    private func retrieveIdentifierRequirementsAndAdvance(coordinator: CryptoOnrampCoordinator) async {
        isLoading?.wrappedValue = true
        defer { isLoading?.wrappedValue = false }
        do {
            setIdentifierRequirements(try await coordinator.retrieveMissingIdentifiers())
            advanceToNextStep()
        } catch {
            presentAlert(
                title: "Unable to determine identifier requirements",
                message: error.localizedDescription
            )
        }
    }

    private func setIdentifierRequirements(_ requirements: ComplianceIdentifierRequirements) {
        identifierRequirements = requirements
        hasSubmittedIdentifiers = !requirements.requiresIdentifierCollection
    }

    private func advanceToNextStep() {
        // Auto-route to KYC info collection based on selected collection mode:
        // - `.original` uses `kyc_verified` demo backend status.
        // - Any non-original mode uses provided level-0 fields.
        let shouldShowKYCInfo = if kycInfoCollectionMode == .original {
            !isKycVerified
        } else {
            !kycLevel.includesLevel0
        }

        // For `.original`, identity verification also routes from this coordinator.
        // EU users also route through identity verification here after EU identifiers and CRS/CARF.
        // Other non-original modes still defer level 1 and identity collection until onramp session / checkout errors.
        let shouldShowIdentity = (kycInfoCollectionMode == .original || isEUCustomer) && !isIdDocumentVerified

        if shouldShowKYCInfo {
            path.append(.kycInfo(collectionMode: kycInfoCollectionMode))
        } else if
            isEUCustomer,
            !hasSubmittedIdentifiers,
            let identifierRequirements,
            identifierRequirements.requiresIdentifierCollection {
            path.append(.complianceIdentifiers(requirements: identifierRequirements))
        } else if isEUCustomer && !hasAcceptedUserAttestation {
            path.append(.userAttestation)
        } else if shouldShowIdentity {
            path.append(.identity)
        } else if let successfulCheckoutMessage {
            path.append(.checkoutSuccess(message: successfulCheckoutMessage))
        } else if let createOnrampSessionResponse, let selectedPaymentMethodDescription, let settlementSpeed {
            path.append(.paymentSummary(createOnrampSessionResponse: createOnrampSessionResponse, selectedPaymentMethodDescription: selectedPaymentMethodDescription, settlementSpeed: settlementSpeed))
        } else if let selectedWallet {
            path.append(.payment(wallet: selectedWallet))
        } else {
            path.append(.wallets)
        }
    }

    private func presentAlert(title: String, message: String) {
        guard let presentingViewController = UIApplication.shared.findTopNavigationController() else { return }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        presentingViewController.present(alertController, animated: true)
    }

    private func resetInternalState() {
        kycLevel = .none
        isKycVerified = false
        isIdDocumentVerified = false
        isEUCustomer = false
        hasSubmittedIdentifiers = false
        hasAcceptedUserAttestation = false
        identifierRequirements = nil
        kycInfoCollectionMode = .original
        selectedWallet = nil
        createOnrampSessionResponse = nil
        selectedPaymentMethodDescription = nil
        settlementSpeed = nil
        successfulCheckoutMessage = nil
    }
}

extension CryptoOnrampFlowCoordinator.Route {

    /// Whether the user should be able to advance backwards from this step.
    var allowsBackNavigation: Bool {
        switch self {
        case .registration, .payment, .paymentSummary:
            true
        case .wallets, .kycInfo, .complianceIdentifiers, .userAttestation, .identity, .checkoutSuccess:
            false
        }
    }

    /// Whether to display the toolbar item for authenticated user actions, such as logging out.
    var showsAuthenticatedUserToolbarItem: Bool {
        switch self {
        case .wallets, .kycInfo, .complianceIdentifiers, .userAttestation, .identity, .payment, .paymentSummary, .checkoutSuccess:
            true
        case .registration:
            false
        }
    }
}

private extension ComplianceIdentifierRequirements {
    var requiresIdentifierCollection: Bool {
        !identifiers.isEmpty || carfTinRequired
    }
}
