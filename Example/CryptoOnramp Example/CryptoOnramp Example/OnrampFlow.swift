//
//  OnrampFlow.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/10/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

enum OnrampFlowStep {
    case kycInfo
    case identityVerification
    case authenticated
}

final class OnrampFlowViewModel: ObservableObject {
    let coordinator: CryptoOnrampCoordinator
    let customerId: String

    @Published var currentStep: OnrampFlowStep = .authenticated

    private var isKycVerified = false
    private var isIdentityVerified = false

    init(coordinator: CryptoOnrampCoordinator, customerId: String) {
        self.coordinator = coordinator
        self.customerId = customerId
    }

    fileprivate func refreshCustomerInfo() async {
        do {
            let response = try await APIClient.shared.fetchCustomerInfo(cryptoCustomerToken: customerId)
            await MainActor.run {
                updateVerificationState(with: response.verifications)
            }
        } catch {
            // TODO: Surface error to the user
            print("Failed to fetch customer info: \(error)")
        }
    }

    fileprivate func markKycVerified() {
        isKycVerified = true
        updateCurrentStep()
    }

    fileprivate func markIdentityVerified() {
        isIdentityVerified = true
        updateCurrentStep()
    }

    private func updateCurrentStep() {
        currentStep = if !isKycVerified {
            .kycInfo
        } else if !isIdentityVerified {
             .identityVerification
        } else {
             .authenticated
        }
    }

    private func updateVerificationState(with verifications: [CustomerInformationResponse.Verification]) {
        isKycVerified = verifications.contains { $0.name == "kyc_verified" && $0.status == "verified" }
        isIdentityVerified = verifications.contains { $0.name == "id_document_verified" && $0.status == "verified" }
        updateCurrentStep()
    }
}

struct OnrampFlowContainerView: View {
    @StateObject private var viewModel: OnrampFlowViewModel

    init(coordinator: CryptoOnrampCoordinator, customerId: String) {
        _viewModel = StateObject(wrappedValue: OnrampFlowViewModel(coordinator: coordinator, customerId: customerId))
    }

    var body: some View {
        ZStack {
            switch viewModel.currentStep {
            case .kycInfo:
                KYCInfoView(coordinator: viewModel.coordinator) {
                    viewModel.markKycVerified()
                }
            case .identityVerification:
                IdentityVerificationView(coordinator: viewModel.coordinator) {
                    viewModel.markIdentityVerified()
                }
            case .authenticated:
                AuthenticatedView(coordinator: viewModel.coordinator, customerId: viewModel.customerId)
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshCustomerInfo()
            }
        }
    }
}

