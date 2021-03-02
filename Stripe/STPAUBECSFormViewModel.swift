//
//  STPAUBECSFormViewModel.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

enum STPAUBECSFormViewField: Int {
    case name
    case email
    case BSBNumber
    case accountNumber
}

class STPAUBECSFormViewModel {
    var name: String?
    var email: String?
    var bsbNumber: String?
    var accountNumber: String?

    var becsDebitParams: STPPaymentMethodAUBECSDebitParams? {
        guard areFieldsComplete(becsFieldsOnly: true) else {
            return nil
        }

        let params = STPPaymentMethodAUBECSDebitParams()
        params.bsbNumber = STPBSBNumberValidator.sanitizedNumericString(for: bsbNumber ?? "")
        params.accountNumber = STPBECSDebitAccountNumberValidator.sanitizedNumericString(
            for: accountNumber ?? "")

        return params
    }

    var paymentMethodParams: STPPaymentMethodParams? {
        guard areFieldsComplete(becsFieldsOnly: false),
            let params = becsDebitParams
        else {
            return nil
        }

        let billing = STPPaymentMethodBillingDetails()
        billing.name = name
        billing.email = email

        return STPPaymentMethodParams(
            aubecsDebit: params,
            billingDetails: billing,
            metadata: nil)
    }

    func formattedString(forInput input: String, in field: STPAUBECSFormViewField) -> String {
        switch field {
        case .name:
            return input
        case .email:
            return input
        case .BSBNumber:
            return STPBSBNumberValidator.formattedSanitizedText(from: input) ?? ""
        case .accountNumber:
            return STPBECSDebitAccountNumberValidator.formattedSanitizedText(
                from: input,
                withBSBNumber: STPBSBNumberValidator.sanitizedNumericString(for: bsbNumber ?? ""))
                ?? ""
        }
    }

    func bsbLabel(forInput input: String?, editing: Bool, isErrorString: UnsafeMutablePointer<Bool>)
        -> String?
    {
        let state = STPBSBNumberValidator.validationState(forText: input ?? "")
        if state == .invalid {
            isErrorString.pointee = true
            return STPLocalizedString(
                "The BSB you entered is invalid.",
                "Error string displayed to user when they enter in an invalid BSB number.")
        } else if state == .incomplete && !editing {
            isErrorString.pointee = true
            return STPLocalizedString(
                "The BSB you entered is incomplete.",
                "Error string displayed to user when they have entered an incomplete BSB number.")
        } else {
            isErrorString.pointee = false
            return STPBSBNumberValidator.identity(forText: input ?? "")
        }
    }

    func bankIcon(forInput input: String?) -> UIImage {
        return STPBSBNumberValidator.icon(forText: input)
    }

    func isFieldComplete(withInput input: String, in field: STPAUBECSFormViewField, editing: Bool)
        -> Bool
    {
        switch field {
        case .name:
            return input.count > 0
        case .email:
            return STPEmailAddressValidator.stringIsValidEmailAddress(input)
        case .BSBNumber:
            return STPBSBNumberValidator.validationState(forText: input) == .complete
        case .accountNumber:
            // If it's currently being edited, we won't consider the account number field complete until it reaches its
            // maximum allowed length
            return STPBECSDebitAccountNumberValidator.validationState(
                forText: input,
                withBSBNumber: STPBSBNumberValidator.sanitizedNumericString(for: bsbNumber ?? ""),
                completeOnMaxLengthOnly: editing) == .complete
        }
    }

    func isInputValid(_ input: String, for field: STPAUBECSFormViewField, editing: Bool) -> Bool {
        switch field {
        case .name:
            return true
        case .email:
            return input.count == 0
                || (editing && STPEmailAddressValidator.stringIsValidPartialEmailAddress(input))
                || (!editing && STPEmailAddressValidator.stringIsValidEmailAddress(input))
        case .BSBNumber:
            let state = STPBSBNumberValidator.validationState(forText: input)
            if editing {
                return state != .invalid
            } else {
                return state != .invalid && state != .incomplete
            }
        case .accountNumber:
            let state = STPBECSDebitAccountNumberValidator.validationState(
                forText: input,
                withBSBNumber: STPBSBNumberValidator.sanitizedNumericString(for: bsbNumber ?? ""),
                completeOnMaxLengthOnly: editing)
            if editing {
                return state != .invalid
            } else {
                return state != .invalid && state != .incomplete
            }
        }
    }

    private func areFieldsComplete(becsFieldsOnly: Bool) -> Bool {
        var fields: [STPAUBECSFormViewField]
        if becsFieldsOnly {
            fields = [
                .BSBNumber,
                .accountNumber,
            ]
        } else {
            fields = [
                .name,
                .email,
                .BSBNumber,
                .accountNumber,
            ]
        }

        for field in fields {
            var input: String?
            switch field {
            case .name:
                input = name
            case .email:
                input = email
            case .BSBNumber:
                input = bsbNumber
            case .accountNumber:
                input = accountNumber
            }

            if let input = input {
                if !isFieldComplete(withInput: input, in: field, editing: false) {
                    return false
                }
            } else {
                return false
            }
        }

        return true
    }
}
