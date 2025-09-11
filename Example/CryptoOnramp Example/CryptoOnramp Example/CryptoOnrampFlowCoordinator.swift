//
//  CryptoOnrampFlowCoordinator.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/10/25.
//

import Foundation
import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

/// Helps to coordinate stepping through a multi-step flow to collect only necessary data based on known account information.
@MainActor
final class CryptoOnrampFlowCoordinator: ObservableObject {

    /// Represents the possible steps in the flow.
    enum Route: Hashable {
        case registration
        case kycInfo
        case identity
        case authenticated
    }

    /// The coordinator responsible for interacting with the necessary APIs, from authentication to checkout.
    let onrampCoordinator: CryptoOnrampCoordinator

    /// Indicates whether the global loading interface should be shown.
    let isLoading: Binding<Bool>

    /// The current navigation path, intended to be used with `NavigationStack`.
    @Published var path: [Route] = []

    private(set) var email: String = ""
    private(set) var selectedScopes: [OAuthScopes] = []
    private var isKycVerified = false
    private var isIdDocumentVerified = false

    private(set) var customerId: String?
    
    /// Creates a new `CryptoOnrampFlowCoordinator`.
    /// - Parameters:
    ///   - onrampCoordinator: The coordinator responsible for interacting with the necessary APIs, from authentication to checkout.
    ///   - isLoading: Indicates whether the global loading interface should be shown.
    init(onrampCoordinator: CryptoOnrampCoordinator, isLoading: Binding<Bool>) {
        self.onrampCoordinator = onrampCoordinator
        self.isLoading = isLoading
    }

    /// Begins the flow for an existing user.
    /// - Parameter customerId: The user's customer id.
    func startForExistingUser(customerId: String) {
        self.customerId = customerId
        Task {
            await refreshCustomerInfoAndPushNext()
        }
    }

    /// Begins the flow for a new, yet-to-be registered user.
    /// - Parameters:
    ///   - email: The user’s email.
    ///   - selectedScopes: The OAuth scopes the user selected.
    func startForNewUser(email: String, selectedScopes: [OAuthScopes]) {
        self.email = email
        self.selectedScopes = selectedScopes
        self.path = [.registration]
    }

    /// Advances to the next step of the flow post-registration.
    /// - Parameter customerId: The user's customer id.
    func advanceAfterRegistration(customerId: String) {
        self.customerId = customerId
        Task {
            await refreshCustomerInfoAndPushNext()
        }
    }

    /// Advances to the next step of the flow post-KYC info collection.
    func advanceAfterKyc() {
        isKycVerified = true
        advanceToNextStep()
    }

    /// Advances to the next step in the flow post-identity verification.
    func advanceAfterIdentity() {
        isIdDocumentVerified = true
        advanceToNextStep()
    }

    private func refreshCustomerInfoAndPushNext() async {
        guard let customerId else { return }
        isLoading.wrappedValue = true
        defer { isLoading.wrappedValue = false }
        do {
            let info = try await APIClient.shared.fetchCustomerInfo(cryptoCustomerToken: customerId)
            isKycVerified = info.isKycVerified
            isIdDocumentVerified = info.isIdDocumentVerified
            advanceToNextStep()
        } catch {
            presentAlert(
                title: "Unable to determine KYC and identity verification statuses",
                message: "Please ensure you have the required OAuth scopes selected and try again.\n\n\(error.localizedDescription)"
            )
        }
    }

    private func advanceToNextStep() {
        if !isKycVerified {
            path.append(.kycInfo)
        } else if !isIdDocumentVerified {
            path.append(.identity)
        } else {
            path.append(.authenticated)
        }
    }

    private func presentAlert(title: String, message: String) {
        guard let presentingViewController = UIApplication.shared.findTopNavigationController() else { return }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        presentingViewController.present(alertController, animated: true)
    }
}

private extension CustomerInformationResponse {
    var isKycVerified: Bool {
        verifications.contains { $0.name == "kyc_verified" && $0.status == "verified" }
    }

    var isIdDocumentVerified: Bool {
        verifications.contains { $0.name == "id_document_verified" && $0.status == "verified" }
    }
}
