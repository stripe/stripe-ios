//
//  STPPaymentMethodOptions.swift
//  StripePayments
//
//  Created by Cameron Sabol on 4/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) public class STPPaymentMethodOptions: NSObject, STPAPIResponseDecodable {

    @_spi(STP) public let usBankAccount: USBankAccount?
    @_spi(STP) public let card: Card?
    @_spi(STP) public let allResponseFields: [AnyHashable: Any]

    @_spi(STP) public init(
        usBankAccount: USBankAccount?,
        card: Card?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.usBankAccount = usBankAccount
        self.card = card
        self.allResponseFields = allResponseFields
    }

    @_spi(STP) public static func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        guard let response = response else {
            return nil
        }

        return STPPaymentMethodOptions(
            usBankAccount: USBankAccount.decodedObject(
                fromAPIResponse: response["us_bank_account"] as? [AnyHashable: Any]
            ),
            card: Card.decodedObject(
                fromAPIResponse: response["card"] as? [AnyHashable: Any]
            ),
            allResponseFields: response
        ) as? Self
    }

}
// MARK: - card

extension STPPaymentMethodOptions {
    @_spi(STP) public class Card: NSObject, STPAPIResponseDecodable {

        @_spi(STP) public let requireCvcRecollection: Bool?
        @_spi(STP) public let allResponseFields: [AnyHashable: Any]

        @_spi(STP) public init(
            requireCvcRecollection: Bool?,
            allResponseFields: [AnyHashable: Any]
        ) {
            self.requireCvcRecollection = requireCvcRecollection
            self.allResponseFields = allResponseFields
        }

        @_spi(STP) public static func decodedObject(
            fromAPIResponse response: [AnyHashable: Any]?
        ) -> Self? {
            guard let response = response,
                let requireCvcRecollection = response["require_cvc_recollection"] as? Bool
            else {
                return nil
            }

            return Card(
                requireCvcRecollection: requireCvcRecollection,
                allResponseFields: response
            ) as? Self
        }
    }
}
// MARK: - us_bank_account

extension STPPaymentMethodOptions {
    @_spi(STP) public class USBankAccount: NSObject, STPAPIResponseDecodable {

        /// Bank account verification method.
        @_spi(STP) @frozen public enum VerificationMethod: String, CaseIterable {
            /// Allows skipping the bank account verification step.
            case skip
            /// Instant verification with fallback to microdeposits.
            case automatic
            /// Instant verification only.
            case instant
            /// Verification using microdeposits.
            case microdeposits
            /// Instant verification with fallback to verification skip.
            case instantOrSkip = "instant_or_skip"
            case unknown
        }

        @_spi(STP) public let setupFutureUsage: STPPaymentIntentSetupFutureUsage?
        @_spi(STP) public let verificationMethod: VerificationMethod
        @_spi(STP) public let allResponseFields: [AnyHashable: Any]

        @_spi(STP) public init(
            setupFutureUsage: STPPaymentIntentSetupFutureUsage?,
            verificationMethod: VerificationMethod,
            allResponseFields: [AnyHashable: Any]
        ) {
            self.setupFutureUsage = setupFutureUsage
            self.verificationMethod = verificationMethod
            self.allResponseFields = allResponseFields
        }

        @_spi(STP) public static func decodedObject(
            fromAPIResponse response: [AnyHashable: Any]?
        ) -> Self? {
            guard let response = response,
                let verificationMethodString = response["verification_method"] as? String
            else {
                return nil
            }

            let setupFutureUsageString = response["setup_future_usage"] as? String

            return USBankAccount(
                setupFutureUsage: setupFutureUsageString != nil
                    ? STPPaymentIntentSetupFutureUsage.init(string: setupFutureUsageString!) : nil,
                verificationMethod: VerificationMethod(rawValue: verificationMethodString)
                    ?? .unknown,
                allResponseFields: response
            ) as? Self
        }
    }
}

// MARK: - Test Helpers
extension STPPaymentMethodOptions {
    var dictionaryValue: [AnyHashable: Any] {
        var dictionaryValue = [AnyHashable: Any]()
        if let usBankAccount = usBankAccount {
            dictionaryValue["us_bank_account"] = usBankAccount.dictionaryValue
        }
        return dictionaryValue.merging(allResponseFields) { a, _ in
            a
        }
    }
}
extension STPPaymentMethodOptions.USBankAccount {
    var dictionaryValue: [AnyHashable: Any] {
        var dictionaryValue = [AnyHashable: Any]()
        dictionaryValue["verification_method"] = verificationMethod.rawValue
        if let setupFutureUsage = setupFutureUsage {
            dictionaryValue["setup_future_usage"] = setupFutureUsage.stringValue
        }
        return dictionaryValue.merging(allResponseFields) { a, _ in
            a
        }
    }
}
