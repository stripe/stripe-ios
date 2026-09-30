//
//  KYCStepUpRecovery.swift
//  CryptoOnramp Example
//

import Foundation

/// Shared logic for recognizing checkout errors that require a KYC/identity step-up, and determining which
/// `KYCRecoveryFlowView.Levels` (if any) should be presented in response.
enum KYCStepUpRecovery {
    enum ErrorCodes {
        static let missingMinimumIdentityVerification = "crypto_onramp_missing_minimum_identity_verification"
        static let missingIdentityVerification = "crypto_onramp_missing_identity_verification"
        static let missingDocumentVerification = "crypto_onramp_missing_document_verification"
    }

    /// Whether the given checkout/session-creation error code indicates a KYC/identity step-up may be needed.
    static func shouldFetchCustomerInfoForRecovery(forErrorCode code: String) -> Bool {
        let code = code.lowercased()
        return code == ErrorCodes.missingMinimumIdentityVerification
            || code == ErrorCodes.missingIdentityVerification
            || code == ErrorCodes.missingDocumentVerification
    }

    /// Determines the step-up levels to present for the given error code and customer info, if any.
    static func recoveryLevels(
        forErrorCode code: String,
        customerInfo: CustomerInformationResponse
    ) -> KYCRecoveryFlowView.Levels? {
        // Intentionally using only the collected fields for determining KYC level.
        // Verifications (i.e. from `customerInfo.kycLevel`) can lag and take
        // more time to change.
        let currentLevel = customerInfo.kycLevelFromFieldsCollected

        guard currentLevel.includesLevel0 else {
            // The user attempted to create an onramp session having never completed Level 0 KYC.
            // This is not a supported flow step-up flow, as they should have been prompted to
            // enter L0 KYC information after authentication.
            return nil
        }

        let code = code.lowercased()
        if code == ErrorCodes.missingMinimumIdentityVerification {
            // In this case, the user has L0 fields, but session creation failed, likely due to
            // a lag in verification status being updated. The user will need to try to check
            // out again after some time.
            return nil
        }

        if code == ErrorCodes.missingIdentityVerification {
            guard !currentLevel.includesLevel1 else {
                // We’re being told L1 fields are missing, but customer information
                // includes L1 fields. This is an unexpected error scenario, and the user
                // should try again.
                return nil
            }

            // Redirect the user to step up to level 1.
            return .init(currentLevel: currentLevel, requiredLevel: .level1)
        }

        if code == ErrorCodes.missingDocumentVerification {
            guard !currentLevel.includesLevel2 else {
                // We’re being told L2 is required, but identity document verification
                // is already complete. This is an unexpected error scenario, and the
                // user should try again.
                return nil
            }

            // Redirect the user to step up to level 2.
            return .init(currentLevel: currentLevel, requiredLevel: .level2)
        }

        // We didn't hit any expected error scenarios that would lead to a step-up
        // redirect, so we return `nil` to report the error normally to the user.
        return nil
    }
}
