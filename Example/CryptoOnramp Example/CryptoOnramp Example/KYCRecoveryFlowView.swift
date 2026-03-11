//
//  KYCRecoveryFlowView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 3/9/26.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

/// A modal flow used when a greater KYC level is required to check out.
/// Supports either:
/// - level 1: KYC collection only, including date of birth and id number (e.g. SSN).
/// - level 2: KYC collection followed by identity verification
struct KYCRecoveryFlowView: View {
    private enum Route: Hashable {
        case identity
    }

    /// The coordinator used for KYC and identity collection.
    let coordinator: CryptoOnrampCoordinator

    /// The customer's current KYC level when entering this flow.
    let currentLevel: KYCLevel

    /// The KYC level required to continue checkout.
    let requiredLevel: KYCLevel

    /// Closure called after the recovery flow succeeds.
    let onSuccess: () -> Void

    @Environment(\.isLoading) private var isLoading
    @Environment(\.dismiss) private var dismiss
    @State private var path: [Route] = []

    // MARK: - View

    var body: some View {
        NavigationStack(path: $path) {
            rootContent
                .toolbar {
                    cancelToolbarItem
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .identity:
                        identityVerificationView
                    }
                }
        }
        .loadingOverlay(isVisible: isLoading.wrappedValue)
    }

    @ViewBuilder
    private var rootContent: some View {
        if shouldCollectLevel1 {
            KYCInfoView(coordinator: coordinator, collectionMode: .kycLevel1StepUp) {
                handleKYCSuccess()
            }
        } else if shouldCollectIdentity {
            identityVerificationView
        } else {
            Color.clear
                .onAppear {
                    finish()
                }
        }
    }

    private var identityVerificationView: some View {
        IdentityVerificationView(coordinator: coordinator) {
            handleIdentitySuccess()
        }
    }

    private var shouldCollectLevel1: Bool {
        requiredLevel.includesLevel1 && !currentLevel.includesLevel1
    }

    private var shouldCollectIdentity: Bool {
        requiredLevel.requiresIdentityDocumentCollection && currentLevel != .level2
    }

    @ToolbarContentBuilder
    private var cancelToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
    }

    private func handleKYCSuccess() {
        if shouldCollectIdentity {
            path.append(.identity)
        } else {
            finish()
        }
    }

    private func handleIdentitySuccess() {
        finish()
    }

    private func finish() {
        dismiss()
        onSuccess()
    }
}
