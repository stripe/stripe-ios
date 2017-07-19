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

    func updateCustomer(withShippingAddress shipping: STPAddress, completion: @escaping STPErrorBlock) {
        self.customer.shippingAddress = shipping
        completion(nil)
    }

    func detachSource(fromCustomer source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        if let index = self.customer.sources.index(where: { $0.stripeID == source.stripeID }) {
            self.customer.sources.remove(at: index)
        }
        completion(nil)
    }
}
