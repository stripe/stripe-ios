//
//  ManualEntryValidator.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/25/22.
//

import Foundation

final class ManualEntryValidator {

    static let routingNumberLength = 9
    static let accountNumberMaxLength = 17

    static func validateRoutingNumber(_ routingNumber: String) -> String? {
        if routingNumber.isEmpty {
            return STPLocalizedString(
                "Routing number is required.",
                "An error message that appears when a user is manually entering their bank account information. This error message appears when the user left the 'Routing number' field blank."
            )
        } else if !isStringDigits(routingNumber, withExactLength: routingNumberLength) {
            return String(
                format: STPLocalizedString(
                    "Please enter %d digits for your routing number.",
                    "An error message that appears when a user is manually entering their bank account information. %d is replaced with the routing number length (usually 9)."
                ),
                routingNumberLength
            )
        } else if !isUSRoutingNumber(routingNumber) {
            return STPLocalizedString(
                "Invalid routing number.",
                "An error message that appears when a user is manually entering their bank account information."
            )
        } else {
            return nil
        }
    }

    static func validateAccountNumber(_ accountNumber: String) -> String? {
        if accountNumber.isEmpty {
            return STPLocalizedString(
                "Account number is required.",
                "An error message that appears when a user is manually entering their bank account information. This error message appears when the user left the 'Account number' field blank."
            )
        } else if !isStringDigits(accountNumber, withMaxLength: accountNumberMaxLength) {
            return String(
                format: STPLocalizedString(
                    "Invalid bank account number: must be at most %d digits long, containing only numbers.",
                    "An error message that appears when a user is manually entering their bank account information. %d is replaced with the account number length (usually 17)."
                ),
                accountNumberMaxLength
            )
        } else {
            return nil
        }
    }

    static func validateAccountNumberConfirmation(
        _ accountNumberConfirmation: String,
        accountNumber: String
    ) -> String? {
        if accountNumberConfirmation.isEmpty {
            return STPLocalizedString(
                "Confirm the account number.",
                "An error message that appears when a user is manually entering their bank account information. This error message appears when the user left the 'Confirm account number' field blank."
            )
        } else if accountNumberConfirmation != accountNumber {
            return STPLocalizedString(
                "Your account numbers don't match.",
                "An error message that appears when a user is manually entering their bank account information. This error message tells the user that the account number they typed doesn't match a previously typed account number."
            )
        } else {
            return nil
        }
    }

    private static func isStringDigits(
        _ string: String,
        withMaxLength maxLength: Int
    ) -> Bool {
        let regex = "^\\d{1,\(maxLength)}$"
        return string.range(of: regex, options: [.regularExpression]) != nil
    }

    private static func isStringDigits(
        _ string: String,
        withExactLength exactLength: Int
    ) -> Bool {
        let regex = "^\\d{\(exactLength)}$"
        return string.range(of: regex, options: [.regularExpression]) != nil
    }

    private static func isUSRoutingNumber(_ routingNumber: String) -> Bool {
        func usRoutingFactor(_ index: Int) -> Int {
            let mod3 = index % 3
            if mod3 == 0 {
                return 3
            } else if mod3 == 1 {
                return 7
            } else {
                return 1
            }
        }

        if routingNumber.range(of: #"^\d{9}$"#, options: [.regularExpression]) != nil {
            let total = routingNumber.enumerated().reduce(0) { partialResult, indexAndCharacter in
                let index = indexAndCharacter.offset
                let character = String(indexAndCharacter.element)

                // the character cast can't fail because we ensure that
                // all characters are digits with the regex
                assert(Int(character) != nil)

                return partialResult + (Int(character) ?? 1) * usRoutingFactor(index)
            }
            return total % 10 == 0
        } else {
            return false
        }
    }
}
