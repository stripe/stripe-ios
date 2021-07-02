//
//  TextFieldElement+IBAN.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension TextFieldElement {
    static func makeIBAN() -> TextFieldElement {
        return TextFieldElement(configuration: IBANConfiguration())
    }
    
    // MARK: - IBANError
    
    enum IBANError: TextFieldValidationError, Equatable {
        case incomplete
        case shouldStartWithCountryCode
        case invalidCountryCode(countryCode: String)
        ///  A catch-all for things like incorrect length, invalid characters, bad checksum.
        case invalidFormat
        
        var localizedDescription: String {
            switch self {
            case .incomplete:
                return STPLocalizedString("The IBAN you entered is incomplete.", "An error message.")
            case .shouldStartWithCountryCode:
                return STPLocalizedString("Your IBAN should start with a two-letter country code.", "An error message.")
            case .invalidCountryCode(let countryCode):
                let localized = STPLocalizedString("The IBAN you entered is invalid, \"%@\" is not a supported country code.", "An error message.")
                return String(format: localized, countryCode)
            case .invalidFormat:
                return NSError.stp_invalidBankAccountIban
            }
        }
        
        func shouldDisplay(isUserEditing: Bool) -> Bool {
            switch self {
            case .incomplete, .invalidFormat:
                return !isUserEditing
            case .shouldStartWithCountryCode, .invalidCountryCode:
                return true
            }
        }
    }
        
    // MARK: IBANConfiguration
    /**
     A text field configuration for an IBAN, or International Bank Account Number, as defined in ISO 13616-1.
     
     - Seealso: https://en.wikipedia.org/wiki/International_Bank_Account_Number
     */
    struct IBANConfiguration: TextFieldElementConfiguration {
        let placeholder: String = STPLocalizedString("IBAN", "IBAN placeholder")
        let maxLength: Int = 34
        /// Ensure it's at least the minimum size assumed by the algorith. Note: ideally, this length depends on the country.
        let minLength: Int = 8

        let disallowedCharacters: CharacterSet = CharacterSet.stp_asciiLetters
            .union(CharacterSet.stp_asciiDigit)
            .inverted
        
        func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams? {
            let sepa = params.paymentMethodParams.sepaDebit ?? STPPaymentMethodSEPADebitParams()
            sepa.iban = text
            params.paymentMethodParams.sepaDebit = sepa
            return params
        }
        
        func makeDisplayText(for text: String) -> NSAttributedString {
            let firstTwoCapitalized = text.prefix(2).uppercased() + text.dropFirst(2)
            let attributed = NSMutableAttributedString(string: firstTwoCapitalized, attributes: [.kern: 0])
            // Put a space between every 4th character
            for i in stride(from: 3, to: attributed.length, by: 4) {
                attributed.addAttribute(.kern, value: 5, range: NSRange(location: i, length: 1))
            }
            return attributed
        }
        
        /**
         The IBAN structure is defined in ISO 13616-1 and consists of a two-letter ISO 3166-1 country code,
         followed by two check digits and up to thirty alphanumeric characters for a BBAN (Basic Bank Account Number)
         which has a fixed length per country and, included within it, a bank identifier with a fixed position and a fixed length per country.
         
         The check digits are calculated based on the scheme defined in ISO/IEC 7064 (MOD97-10).
         We perform the algorithm as described in https://en.wikipedia.org/wiki/International_Bank_Account_Number#Validating_the_IBAN
         */
        func validate(text: String, isOptional: Bool) -> ElementValidationState {
            let iBAN = text.uppercased()
            guard !iBAN.isEmpty else {
                return isOptional ? .valid : .invalid(Error.empty)
            }
            
            // Validate starts with a two-letter country code
            let countryValidationResult = Self.validateCountryCode(iBAN)
            guard case .valid = countryValidationResult else {
                return countryValidationResult
            }
            
            // Validate that the total IBAN length is correct
            guard iBAN.count > minLength else {
                return .invalid(IBANError.incomplete)
            }
            
            // Validate it's up to 34 alphanumeric characters long
            guard
                iBAN.count <= maxLength,
                iBAN.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber)}) else {
                    return .invalid(IBANError.invalidFormat)
                }
            
            // Move the four initial characters to the end of the string
            // e.g. "GB1234" -> "34GB12"
            let reorderedIBAN = iBAN.dropFirst(4) + iBAN.prefix(4)
            
            // Replace each letter in the string with two digits, thereby expanding the string, where A = 10, B = 11, ..., Z = 35
            // e.g., "GB82" -> "161182"
            let oneBigNumber = Self.transformToASCIIDigits(String(reorderedIBAN))
            
            // Interpret the string as a decimal integer and compute the remainder of that number on division by 97
            // If the IBAN is valid, the remainder equals 1.
            // e.g., "00001011" -> Int(1011)
            guard Self.mod97(oneBigNumber) == 1 else {
                return .invalid(IBANError.invalidFormat)
            }
            return .valid
        }
        
        // MARK: - Helper methods
        
        /// Validates that the iBAN begins with a two-letter country code
        static func validateCountryCode(_ iBAN: String) -> ElementValidationState {
            let countryCode = String(iBAN.prefix(2))
            guard countryCode.allSatisfy({ $0.isASCII && $0.isLetter }) else {
                // The user put in numbers or something weird; let them know the iban should start with a country code
                return .invalid(IBANError.shouldStartWithCountryCode)
            }

            guard countryCode.count == 2 else {
                return .invalid(IBANError.incomplete)
            }
            // Validate that the country code exists
            guard NSLocale.isoCountryCodes.contains(countryCode) else {
                return .invalid(IBANError.invalidCountryCode(countryCode: countryCode))
            }
            return .valid
        }
        
        /// Interprets `bigNumber` as a decimal integer and compute the remainder of that number on division by 97
        /// - Note: Does not handle empty strings
        static func mod97(_ bigNumber: String) -> Int? {
            return bigNumber.reduce(0) { (previousMod, char) in
                guard let previousMod = previousMod,
                      let value = Int(String(char)) else {
                          return nil
                      }
                let factor = value < 10 ? 10 : 100
                return (factor * previousMod + value) % 97
            }
        }
        
        /// Replaces each letter in the string with two digits, thereby expanding the string, where A = 10, B = 11, ..., Z = 35
        /// e.g., "GB82" -> "161182"
        /// - Note: Assumes the string is alphanumeric
        static func transformToASCIIDigits(_ string: String) -> String {
            return string.reduce("") { result, character in
                if character.isLetter {
                    guard let asciiValue = character.asciiValue else {
                        return ""
                    }
                    let digit = Int(asciiValue) - asciiValueOfA + 10
                    return result + String(digit)
                } else if character.isNumber {
                    return result + String(character)
                } else {
                    return ""
                }
            }
        }
    }
}

fileprivate let asciiValueOfA: Int = Int(Character("A").asciiValue!)
