//
//  VerificationFlowResult+Equatable.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/17/21.
//

import Foundation
@testable import StripeIdentity

extension IdentityVerificationSheet.VerificationFlowResult: Equatable {
    public static func == (lhs: IdentityVerificationSheet.VerificationFlowResult, rhs: IdentityVerificationSheet.VerificationFlowResult) -> Bool {
        switch (lhs, rhs) {
        case (.flowCompleted, .flowCompleted),
             (.flowCanceled, .flowCanceled),
             (.flowFailed, .flowFailed):
            return true
        default:
            return false
        }
    }
}
