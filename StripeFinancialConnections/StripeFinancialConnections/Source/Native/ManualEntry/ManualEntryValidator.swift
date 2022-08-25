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
            return "Routing number is required."
        } else if !isStringDigits(routingNumber, andExactLength: routingNumberLength) {
            return "Please enter 9 digits for your routing number."
        } else if !isUSRoutingNumber(routingNumber) {
            return "Invalid routing number."
        } else {
            return nil
        }
    }
    
    static func validateAccountNumber(_ accountNumber: String) -> String? {
        if accountNumber.isEmpty {
            return "Account number is required."
        } else if !isStringDigits(accountNumber, andMaxLength: accountNumberMaxLength) {
            return "Invalid bank account number: must be at most \(accountNumberMaxLength) digits long."
        } else {
            return nil
        }
    }
    
    static func validateAccountNumberConfirmation(_ accountNumberConfirmation: String, accountNumber: String) -> String? {
        if accountNumberConfirmation.isEmpty {
            return "Confirm the account number."
        } else if accountNumberConfirmation != accountNumber {
            return "Your account numbers don't match."
        } else {
            return nil
        }
    }
    
    private static func isStringDigits(_ string: String, andMaxLength maxLength: Int) -> Bool {
        let regex = "^\\d{1,\(maxLength)}$"
        return string.range(of: regex, options: [.regularExpression]) != nil
    }
    
    private static func isStringDigits(_ string: String, andExactLength exactLength: Int) -> Bool {
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
