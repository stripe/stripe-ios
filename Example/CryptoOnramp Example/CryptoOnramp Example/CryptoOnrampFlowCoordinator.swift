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

enum FlowRoute: Hashable {
    case registration
    case kycInfo
    case identity
    case authenticated
}

@MainActor
final class CryptoOnrampFlowCoordinator: ObservableObject {
    let onrampCoordinator: CryptoOnrampCoordinator
    let isLoading: Binding<Bool>

    @Published var path: [FlowRoute] = []

    private(set) var email: String = ""
    private(set) var selectedScopes: [OAuthScopes] = []
    private var isKycVerified = false
    private var isIdDocumentVerified = false

    private(set) var customerId: String?

    init(onrampCoordinator: CryptoOnrampCoordinator, isLoading: Binding<Bool>) {
        self.onrampCoordinator = onrampCoordinator
        self.isLoading = isLoading
    }

    func startForExistingUser(customerId: String) {
        self.customerId = customerId
        Task {
            await refreshCustomerInfoAndPushNext()
        }
    }

    func startForNewUser(email: String, selectedScopes: [OAuthScopes]) {
        self.email = email
        self.selectedScopes = selectedScopes
        self.path = [.registration]
    }

    func advanceAfterRegistration(customerId: String) {
        self.customerId = customerId
        Task {
            await refreshCustomerInfoAndPushNext()
        }
    }

    func advanceAfterKyc() {
        isKycVerified = true
        advanceToNextStep()
    }

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
            // TODO: Surface customer info fetch errors to the user
            print("Failed to fetch customer info: \(error)")
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
}

private extension CustomerInformationResponse {
    var isKycVerified: Bool {
        verifications.contains { $0.name == "kyc_verified" && $0.status == "verified" }
    }

    var isIdDocumentVerified: Bool {
        verifications.contains { $0.name == "id_document_verified" && $0.status == "verified" }
    }
}
