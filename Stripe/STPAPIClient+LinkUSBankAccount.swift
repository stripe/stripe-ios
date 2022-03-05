//
//  STPAPIClient+LinkUSBankAccount.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

typealias STPLinkAccountForBankAccountBlock = (LinkAccountSession?, Error?) -> Void

extension STPAPIClient {
    func linkAccountForUSBankAccount(setupIntentID: String,
                                     clientSecret: String,
                                     customerName: String,
                                     customerEmailAddress: String?,
                                     completion: @escaping STPLinkAccountForBankAccountBlock) {
        let endpoint: String = "setup_intents/\(setupIntentID)/link_account_session"
        linkAccountForUSBankAccount(endpoint: endpoint,
                                    clientSecret: clientSecret,
                                    customerName: customerName,
                                    customerEmailAddress: customerEmailAddress,
                                    completion: completion)
    }
    func linkAccountForUSBankAccount(paymentIntentID: String,
                                     clientSecret: String,
                                     customerName: String,
                                     customerEmailAddress: String?,
                                     completion: @escaping STPLinkAccountForBankAccountBlock) {
        let endpoint: String = "payment_intents/\(paymentIntentID)/link_account_session"
        linkAccountForUSBankAccount(endpoint: endpoint,
                                    clientSecret: clientSecret,
                                    customerName: customerName,
                                    customerEmailAddress: customerEmailAddress,
                                    completion: completion)
        
    }
    private func linkAccountForUSBankAccount(endpoint: String,
                                             clientSecret: String,
                                             customerName: String,
                                             customerEmailAddress: String?,
                                             completion: @escaping STPLinkAccountForBankAccountBlock) {
        var parameters: [String: Any] = [
            "client_secret": clientSecret,
            "payment_method_data[type]": "us_bank_account",
            "payment_method_data[billing_details][name]": customerName
        ]

        if let customerEmailAddress = customerEmailAddress {
            parameters["payment_method_data[billing_details][email]"] = customerEmailAddress
        }

        APIRequest<LinkAccountSession>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { linkAccountSession, _, error in
            completion(linkAccountSession, error)
        }
    }
}
