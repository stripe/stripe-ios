//
//  STPPaymentMethodOptions.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 4/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

class STPPaymentMethodOptions: NSObject, STPAPIResponseDecodable {

    let usBankAccount: USBankAccount?
    let allResponseFields: [AnyHashable : Any]

    internal init(usBankAccount: USBankAccount?,
                  allResponseFields: [AnyHashable : Any]) {
        self.usBankAccount = usBankAccount
        self.allResponseFields = allResponseFields
    }

    static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
        guard let response = response else {
            return nil
        }

        return STPPaymentMethodOptions(usBankAccount: USBankAccount.decodedObject(fromAPIResponse: response["us_bank_account"] as? [AnyHashable: Any]),
                                       allResponseFields: response) as? Self
    }

}

// MARK: - us_bank_account

extension STPPaymentMethodOptions {
    class USBankAccount: NSObject, STPAPIResponseDecodable {

        /// Bank account verification method.
        enum VerificationMethod: String, CaseIterable {
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

        let setupFutureUsage: STPPaymentIntentSetupFutureUsage?
        let verificationMethod: VerificationMethod
        let allResponseFields: [AnyHashable : Any]

        internal init(setupFutureUsage: STPPaymentIntentSetupFutureUsage?,
                      verificationMethod: VerificationMethod,
                      allResponseFields: [AnyHashable : Any]) {
            self.setupFutureUsage = setupFutureUsage
            self.verificationMethod = verificationMethod
            self.allResponseFields = allResponseFields
        }


        static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
            guard let response = response,
            let verificationMethodString = response["verification_method"] as? String else {
                return nil
            }

            let setupFutureUsageString = response["setup_future_usage"] as? String

            return USBankAccount(setupFutureUsage: setupFutureUsageString != nil ? STPPaymentIntentSetupFutureUsage.init(string: setupFutureUsageString!) : nil,
                                 verificationMethod: VerificationMethod(rawValue: verificationMethodString) ?? .unknown,
                                 allResponseFields: response) as? Self
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
        return dictionaryValue.merging(allResponseFields) { a, b in
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
        return dictionaryValue.merging(allResponseFields) { a, b in
            a
        }
    }
}
