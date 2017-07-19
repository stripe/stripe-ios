//
//  MockCustomerContext.swift
//  UI Demo
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
        // Preload the mock customer with saved cards
        let visa = [
            "id": "preloaded_visa",
            "exp_month": "10",
            "exp_year": "2020",
            "last4": "1881",
            "brand": "visa",
        ]
        if let card = STPCard.decodedObject(fromAPIResponse: visa) {
            self.mockSources.append(card)
            self.mockDefaultSource = card
        }
        let masterCard = [
            "id": "preloaded_mastercard",
            "exp_month": "10",
            "exp_year": "2020",
            "last4": "8210",
            "brand": "mastercard",
        ]
        if let card = STPCard.decodedObject(fromAPIResponse: masterCard) {
            self.mockSources.append(card)
        }
        let amex = [
            "id": "preloaded_amex",
            "exp_month": "10",
            "exp_year": "2020",
            "last4": "0005",
            "brand": "american express",
        ]
        if let card = STPCard.decodedObject(fromAPIResponse: amex) {
            self.mockSources.append(card)
        }
    }

    override var sources: [STPSourceProtocol] {
        get {
            return self.mockSources
        }
        set {
            self.mockSources = newValue
        }
    }

    override var defaultSource: STPSourceProtocol? {
        get {
            return self.mockDefaultSource
        }
        set {
            self.mockDefaultSource = newValue
        }
    }

    override var shippingAddress: STPAddress? {
        get {
            return self.mockShippingAddress
        }
        set {
            self.mockShippingAddress = newValue
        }
    }
}

class MockCustomerContext: STPCustomerContext {

    let customer = MockCustomer()

    override func retrieveCustomer(_ completion: STPCustomerCompletionBlock? = nil) {
        if let completion = completion {
            completion(self.customer, nil)
        }
    }

    override func attachSource(toCustomer source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        if let token = source as? STPToken, let card = token.card {
            self.customer.sources.append(card)
        }
        completion(nil)
    }

    override func selectDefaultCustomerSource(_ source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        if self.customer.sources.contains(where: { $0.stripeID == source.stripeID }) {
            self.customer.defaultSource = source
        }
        completion(nil)
    }

    func updateCustomer(withShippingAddress shipping: STPAddress, completion: STPErrorBlock?) {
        self.customer.shippingAddress = shipping
        if let completion = completion {
            completion(nil)
        }
    }

    func detachSource(fromCustomer source: STPSourceProtocol, completion: STPErrorBlock?) {
        if let index = self.customer.sources.index(where: { $0.stripeID == source.stripeID }) {
            self.customer.sources.remove(at: index)
        }
        if let completion = completion {
            completion(nil)
        }
    }
}
