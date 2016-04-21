//
//  BackendAPIAdapter.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe

class BackendAPIAdapter: NSObject, STPBackendAPIAdapter {
    @objc var cards: [STPCard]? = []
    @objc var selectedCard: STPCard?
    @objc var shippingAddress: STPAddress?
    
    @objc func retrieveCards(completion: STPCardCompletionBlock) {
        completion(self.selectedCard, self.cards, nil)
    }

    @objc func selectCard(card: STPCard, completion: STPCardCompletionBlock) {
        self.selectedCard = card
        completion(card, self.cards, nil)
    }
    
    @objc func addToken(token: STPToken, completion: STPCardCompletionBlock) {
        self.cards?.append(token.card!)
        self.selectCard(token.card!, completion: completion)
    }

    @objc func retrieveCustomerShippingAddress(completion: STPAddressCompletionBlock) {
        completion(self.shippingAddress, nil)
    }

    @objc func updateCustomerShippingAddress(shippingAddress: STPAddress, completion: STPAddressCompletionBlock) {
        self.shippingAddress = shippingAddress
        completion(self.shippingAddress, nil)
    }

}
