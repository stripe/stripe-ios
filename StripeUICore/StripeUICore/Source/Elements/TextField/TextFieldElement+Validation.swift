//
//  TextFieldElement+Validation.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public extension TextFieldElement {
    @frozen enum ValidationState {
        case valid
        case invalid(_ error: TextFieldValidationError)
    }

    /// A general-purpose TextFieldValidationError.
    /// If it doesn't suit your text field's needs, create a new enum instead of modifying this one!
    @frozen enum Error: TextFieldValidationError, Equatable {
        /// An empty text field differs from incomplete in that it never displays an error.
        case empty
        case incomplete(localizedDescription: String)
        case invalid(localizedDescription: String)

        public func shouldDisplay(isUserEditing: Bool) -> Bool {
            switch self {
            case .empty:
                return false
            case .incomplete, .invalid:
                // By default, invalid errors aren't displayed.
                // This makes sense when input that is invalid may become valid after further user input
                return !isUserEditing
            }
        }

        public var localizedDescription: String {
            switch self {
            case .incomplete(let localizedDescription):
                return localizedDescription
            case .invalid(let localizedDescription):
                return localizedDescription
            case .empty:
                return ""
            }
        }
    }
}

/**
 - Seealso: `ElementValidation.swift`
 - Seealso: `SectionElement` uses this to determine whether it should show the error or not.
 */
@_spi(STP) public protocol TextFieldValidationError: ElementValidationError {
    /**
     Some TextFieldElement validation errors should only be displayed to the user if they're finished typing, while others should
     always be shown.

     For example, most fields in an "incomplete" state won't display an "incomplete" error until the user has finished typing.
     
     - Parameter isUserEditing: Whether or not the user is editing the field that is in error.
     - Returns: Whether or not to display the error.
     - Note: The default implementation always returns `true`
     */
    func shouldDisplay(isUserEditing: Bool) -> Bool

    var localizedDescription: String { get }
}

extension TextFieldValidationError {
    func shouldDisplay(isUserEditing: Bool) -> Bool {
        return true
    }
}

// MARK: - ElementValidationState
extension ElementValidationState {
    /// Converts a `TextFieldElement.ValidationState` to an `ElementValidationState`
    /// The only difference between the two is that the latter includes `isUserEditing` as part of its state so that it knows whether the error should display or not.
    init(from validationState: TextFieldElement.ValidationState, isUserEditing: Bool) {
        switch validationState {
        case .valid:
            self = .valid
        case .invalid(let error):
            self = .invalid(error: error, shouldDisplay: error.shouldDisplay(isUserEditing: isUserEditing))
        }
    }
}
