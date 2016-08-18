//
//  MyAPIClient.swift
//  
//
//  Created by Ben Guo on 8/18/16.
//
//

import Foundation
import Stripe

class MyAPIClient: NSObject, STPBackendAPIAdapter {

    var defaultSource: STPCard? = nil
    var sources: [STPCard] = []

    @objc func retrieveCustomer(completion: STPCustomerCompletionBlock) {
        let customer = STPCustomer(stripeID: "cus_test", defaultSource: self.defaultSource, sources: self.sources)
        completion(customer, nil)
    }

    @objc func selectDefaultCustomerSource(source: STPSource, completion: STPErrorBlock) {
        if let token = source as? STPToken {
            self.defaultSource = token.card
        }
        completion(nil)
    }

    @objc func attachSourceToCustomer(source: STPSource, completion: STPErrorBlock) {
        if let token = source as? STPToken, card = token.card {
            self.sources.append(card)
            self.defaultSource = card
        }
        completion(nil)
    }
}
