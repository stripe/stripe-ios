//
//  ElementValidation.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

// MARK: - ElementValidationState

enum ElementValidationState {
    case valid
    case invalid(_ error: ElementValidationStateError)
}

/// :nodoc:
extension ElementValidationState: Equatable {
    static func == (lhs: ElementValidationState, rhs: ElementValidationState) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid):
            return true
        case let (.invalid(lhsError), .invalid(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - ElementValidationError

protocol ElementValidationStateError: Error {
    var localizedDescription: String { get }
}

func == (lhs: ElementValidationStateError, rhs: ElementValidationStateError) -> Bool {
    return (lhs as NSError).isEqual(rhs as NSError)
}
