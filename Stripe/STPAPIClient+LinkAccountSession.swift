//
//  STPAPIClient+LinkAccountSession.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

typealias STPLinkAccountSessionBlock = (LinkAccountSession?, Error?) -> Void
typealias STPLinkAccountSessionsAttachPaymentIntentBlock = (STPPaymentIntent?, Error?) -> Void
typealias STPLinkAccountSessionsAttachSetupIntentBlock = (STPSetupIntent?, Error?) -> Void


extension STPAPIClient {
    func createLinkAccountSession(setupIntentID: String,
                                  clientSecret: String,
                                  paymentMethodType: STPPaymentMethodType,
                                  customerName: String?,
                                  customerEmailAddress: String?,
                                  completion: @escaping STPLinkAccountSessionBlock) {
        let endpoint: String = "setup_intents/\(setupIntentID)/link_account_sessions"
        linkAccountSessions(endpoint: endpoint,
                            clientSecret: clientSecret,
                            paymentMethodType: paymentMethodType,
                            customerName: customerName,
                            customerEmailAddress: customerEmailAddress,
                            completion: completion)
    }

    func createLinkAccountSession(paymentIntentID: String,
                                  clientSecret: String,
                                  paymentMethodType: STPPaymentMethodType,
                                  customerName: String?,
                                  customerEmailAddress: String?,
                                  completion: @escaping STPLinkAccountSessionBlock) {
        let endpoint: String = "payment_intents/\(paymentIntentID)/link_account_sessions"
        linkAccountSessions(endpoint: endpoint,
                            clientSecret: clientSecret,
                            paymentMethodType: paymentMethodType,
                            customerName: customerName,
                            customerEmailAddress: customerEmailAddress,
                            completion: completion)
        
    }

    // MARK: - Helper
    private func linkAccountSessions(endpoint: String,
                                     clientSecret: String,
                                     paymentMethodType: STPPaymentMethodType,
                                     customerName: String?,
                                     customerEmailAddress: String?,
                                     completion: @escaping STPLinkAccountSessionBlock) {
        var parameters: [String: Any] = [
            "client_secret": clientSecret
        ]
        if let paymentMethodType = STPPaymentMethod.string(from: paymentMethodType) {
            parameters["payment_method_data[type]"] = paymentMethodType
        }
        if let customerName = customerName {
            parameters["payment_method_data[billing_details][name]"] = customerName
        }
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
    
    func attachLinkAccountSession(setupIntentID: String,
                                  linkAccountSessionID: String,
                                  clientSecret: String,
                                  completion: @escaping STPLinkAccountSessionsAttachSetupIntentBlock) {
        let endpoint: String = "setup_intents/\(setupIntentID)/link_account_sessions/\(linkAccountSessionID)/attach"
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["payment_method"],
        ]
        APIRequest<STPSetupIntent>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { setupIntent, _, error in
            completion(setupIntent, error)
        }
    }
    
    func attachLinkAccountSession(paymentIntentID: String,
                                  linkAccountSessionID: String,
                                  clientSecret: String,
                                  completion: @escaping STPLinkAccountSessionsAttachPaymentIntentBlock) {
        let endpoint: String = "payment_intents/\(paymentIntentID)/link_account_sessions/\(linkAccountSessionID)/attach"
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["payment_method"],
        ]
        APIRequest<STPPaymentIntent>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { paymentIntent, _, error in
            completion(paymentIntent, error)
        }
    }
    
}
