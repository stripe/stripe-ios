//
//  TextFieldElement+AddressFactory.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension TextFieldElement {
    
    // MARK: - Generic Errors
    
    enum Error: TextFieldValidationError, Equatable {
        /// An empty text field differs from incomplete in that it never displays an error.
        case empty
        case incomplete(localizedDescription: String)
        case invalid(localizedDescription: String)
        
        func shouldDisplay(isUserEditing: Bool) -> Bool {
            switch self {
            case .empty:
                return false
            case .incomplete, .invalid:
                return !isUserEditing
            }
        }
        
        var localizedDescription: String {
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
    
    // MARK: - Address
    
    enum Address {
        
        // MARK: - Name
        
        struct NameConfiguration: TextFieldElementConfiguration {
            let placeholder = STPLocalizedString("Name", "Label for Name field on form")
            
            func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams? {
                let billingDetails = params.paymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
                billingDetails.name = text
                params.paymentMethodParams.billingDetails = billingDetails
                return params
            }
            
            func validate(text: String, isOptional: Bool) -> ElementValidationState {
                if text.isEmpty && !isOptional {
                    return .invalid(Error.empty)
                }
                return .valid
            }
        }
        
        static func makeName() -> TextFieldElement {
            return TextFieldElement(configuration: NameConfiguration())
        }
        
        // MARK: - Email
        
        struct EmailConfiguration: TextFieldElementConfiguration {
            let disallowedCharacters: CharacterSet = .whitespacesAndNewlines
            let invalidError = Error.invalid(
                localizedDescription: STPLocalizedString(
                    "Your email is invalid.",
                    "Error message when email is invalid"
                )
            )
            let placeholder = STPLocalizedString("Email", "Label for Email field on form")
            
            func validate(text: String, isOptional: Bool) -> ElementValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }
                if STPEmailAddressValidator.stringIsValidEmailAddress(text) {
                    return .valid
                } else {
                    return .invalid(invalidError)
                }
            }
            
            func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams? {
                let billingDetails = params.paymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
                billingDetails.email = text
                params.paymentMethodParams.billingDetails = billingDetails
                return params
            }
            
            func makeKeyboardProperties(for text: String) -> TextFieldElement.ViewModel.KeyboardProperties {
                return .init(type: .emailAddress, autocapitalization: .none)
            }
        }
        
        static func makeEmail() -> TextFieldElement {
            return TextFieldElement(configuration: EmailConfiguration())
        }
    }
}
    

