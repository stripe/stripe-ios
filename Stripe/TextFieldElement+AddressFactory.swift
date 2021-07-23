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
    
    // MARK: - Address
    
    enum Address {
        
        // MARK: - Name
        
        struct NameConfiguration: TextFieldElementConfiguration {
            let label = STPLocalizedString("Name", "Label for Name field on form")
            
            func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams? {
                let billingDetails = params.paymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
                billingDetails.name = text
                params.paymentMethodParams.billingDetails = billingDetails
                return params
            }
            
            func keyboardProperties(for text: String) -> TextFieldElement.ViewModel.KeyboardProperties {
                return .init(type: .namePhonePad, textContentType: .name, autocapitalization: .words)
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
            let label = STPLocalizedString("Email", "Label for Email field on form")
            
            func validate(text: String, isOptional: Bool) -> ValidationState {
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
            
            func keyboardProperties(for text: String) -> TextFieldElement.ViewModel.KeyboardProperties {
                return .init(type: .emailAddress, textContentType: .emailAddress, autocapitalization: .none)
            }
        }
        
        static func makeEmail() -> TextFieldElement {
            return TextFieldElement(configuration: EmailConfiguration())
        }
        
        // MARK: - Line1, Line2
        
        struct LineConfiguration: TextFieldElementConfiguration {
            enum LineType {
                case line1
                case line2
            }
            let lineType: LineType
            var label: String {
                switch lineType {
                case .line1:
                    return STPLocalizedString("Address line 1", "Label for address line 1 field")
                case .line2:
                    return STPLocalizedString("Address line 2", "Label for address line 2 field")
                }
            }
            
            func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams? {
                let billingDetails = params.paymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
                let address = billingDetails.address ?? STPPaymentMethodAddress()
                switch lineType {
                case .line1:
                    address.line1 = text
                case .line2:
                    address.line2 = text
                }
                billingDetails.address = address
                params.paymentMethodParams.billingDetails = billingDetails
                return params
            }
        }
        
        static func makeLine1() -> TextFieldElement {
            let line1 = TextFieldElement(configuration: LineConfiguration(lineType: .line1))
            return line1
        }
        
        static func makeLine2() -> TextFieldElement {
            let line2 = TextFieldElement(configuration: LineConfiguration(lineType: .line2))
            line2.isOptional = true // Hardcode all line2 as optional
            return line2
        }
        
        // MARK: - City/Locality
        
        struct CityConfiguration: TextFieldElementConfiguration {
            let label: String

            func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams? {
                let billingDetails = params.paymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
                let address = billingDetails.address ?? STPPaymentMethodAddress()
                address.city = text
                billingDetails.address = address
                params.paymentMethodParams.billingDetails = billingDetails
                return params
            }
            
            func keyboardProperties(for text: String) -> TextFieldElement.ViewModel.KeyboardProperties {
                return .init(type: .default, textContentType: .addressCity, autocapitalization: .words)
            }
        }
        
        // MARK: - State/Province/Administrative area/etc.
        
        struct StateConfiguration: TextFieldElementConfiguration {
            let label: String

            func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams? {
                let billingDetails = params.paymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
                let address = billingDetails.address ?? STPPaymentMethodAddress()
                address.state = text
                billingDetails.address = address
                params.paymentMethodParams.billingDetails = billingDetails
                return params
            }
            
            func keyboardProperties(for text: String) -> TextFieldElement.ViewModel.KeyboardProperties {
                return .init(type: .default, textContentType: .addressState, autocapitalization: .words)
            }
        }
        
        // MARK: - Postal code/Zip code
        
        struct PostalCodeConfiguration: TextFieldElementConfiguration {
            let regex: String?
            let label: String

            func validate(text: String, isOptional: Bool) -> ValidationState {
                if text.isEmpty {
                    return isOptional ? .valid : .invalid(Error.empty)
                }
                if regex != nil {
                   // verify
                }
                return .valid
            }
            
            func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams? {
                let billingDetails = params.paymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
                let address = billingDetails.address ?? STPPaymentMethodAddress()
                address.state = text
                billingDetails.address = address
                params.paymentMethodParams.billingDetails = billingDetails
                return params
            }
            
            func keyboardProperties(for text: String) -> TextFieldElement.ViewModel.KeyboardProperties {
                return .init(type: .default, textContentType: .postalCode, autocapitalization: .allCharacters)
            }
        }
    }
}
