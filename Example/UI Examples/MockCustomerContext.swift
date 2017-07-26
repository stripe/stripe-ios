//
//  MockCustomerContext.swift
//  UI Examples
//
//  Created by Ben Guo on 7/18/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Foundation
import Stripe

class MockCustomer: STPCustomer {
    var mockSources: [STPSourceProtocol] = []
    var mockDefaultSource: STPSourceProtocol? = nil
    var mockShippingAddress: STPAddress?

    override init() {
        /** 
         Preload the mock customer with saved cards.
         last4 values are from test cards: https://stripe.com/docs/testing#cards
         Not using the "4242" and "4444" numbers, since those are the easiest 
         to remember and fill.
        */
        let visa = [
            "id": "preloaded_visa",
            "exp_month": "10",
            "exp_year": "2020",
            "last4": "1881",
            "brand": "visa",
        ]
        if let card = STPCard.decodedObject(fromAPIResponse: visa) {
            mockSources.append(card)
        }
        let masterCard = [
            "id": "preloaded_mastercard",
            "exp_month": "10",
            "exp_year": "2020",
            "last4": "8210",
            "brand": "mastercard",
        ]
        if let card = STPCard.decodedObject(fromAPIResponse: masterCard) {
            mockSources.append(card)
        }
        let amex = [
            "id": "preloaded_amex",
            "exp_month": "10",
            "exp_year": "2020",
            "last4": "0005",
            "brand": "american express",
        ]
        if let card = STPCard.decodedObject(fromAPIResponse: amex) {
            mockSources.append(card)
        }
    }

    override var sources: [STPSourceProtocol] {
        get {
            return mockSources
        }
        set {
            mockSources = newValue
        }
    }

    override var defaultSource: STPSourceProtocol? {
        get {
            return mockDefaultSource
        }
        set {
            mockDefaultSource = newValue
        }
    }

    override var shippingAddress: STPAddress? {
        get {
            return mockShippingAddress
        }
        set {
            mockShippingAddress = newValue
        }
    }
}

class MockCustomerContext: STPCustomerContext {

    let customer = MockCustomer()

    override func retrieveCustomer(_ completion: STPCustomerCompletionBlock? = nil) {
        if let completion = completion {
            completion(customer, nil)
        }
    }

    override func attachSource(toCustomer source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        if let token = source as? STPToken, let card = token.card {
            customer.sources.append(card)
        }
        completion(nil)
    }

    override func selectDefaultCustomerSource(_ source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        if customer.sources.contains(where: { $0.stripeID == source.stripeID }) {
            customer.defaultSource = source
        }
        completion(nil)
    }

    func updateCustomer(withShippingAddress shipping: STPAddress, completion: STPErrorBlock?) {
        customer.shippingAddress = shipping
        if let completion = completion {
            completion(nil)
        }
    }

    func detachSource(fromCustomer source: STPSourceProtocol, completion: STPErrorBlock?) {
        if let index = customer.sources.index(where: { $0.stripeID == source.stripeID }) {
            customer.sources.remove(at: index)
        }
        if let completion = completion {
            completion(nil)
        }
    }
}
