//
//  MockCustomerContext.swift
//  UI Examples
//
//  Created by Ben Guo on 7/18/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Foundation
@testable import Stripe

class MockCustomer: STPCustomer {
    var mockPaymentMethods: [STPPaymentMethod] = []
    var mockDefaultPaymentMethod: STPPaymentMethod?
    var mockShippingAddress: STPAddress?

    init() {
        super.init(stripeID: "", defaultSource: nil, sources: [], shippingAddress: nil, allResponseFields: [:])
        /** 
         Preload the mock customer with saved cards.
         last4 values are from test cards: https://stripe.com/docs/testing#cards
         Not using the "4242" and "4444" numbers, since those are the easiest 
         to remember and fill.
        */
        let visa = [
            "card": [
                "id": "preloaded_visa",
                "exp_month": "10",
                "exp_year": "2020",
                "last4": "1881",
                "brand": "visa"
            ],
            "type": "card",
            "id": "preloaded_visa"
            ] as [String: Any]
        if let card = STPPaymentMethod.decodedObject(fromAPIResponse: visa) {
            mockPaymentMethods.append(card)
        }
        let masterCard = [
            "card": [
                "id": "preloaded_mastercard",
                "exp_month": "10",
                "exp_year": "2020",
                "last4": "8210",
                "brand": "mastercard"
            ],
            "type": "card",
            "id": "preloaded_mastercard"
            ] as [String: Any]
        if let card = STPPaymentMethod.decodedObject(fromAPIResponse: masterCard) {
            mockPaymentMethods.append(card)
        }
        let amex = [
            "card": [
                "id": "preloaded_amex",
                "exp_month": "10",
                "exp_year": "2020",
                "last4": "0005",
                "brand": "amex"
            ],
            "type": "card",
            "id": "preloaded_amex"
            ] as [String: Any]
        if let card = STPPaymentMethod.decodedObject(fromAPIResponse: amex) {
            mockPaymentMethods.append(card)
        }
    }

    var paymentMethods: [STPPaymentMethod] {
        get {
            return mockPaymentMethods
        }
        set {
            mockPaymentMethods = newValue
        }
    }

    var defaultPaymentMethod: STPPaymentMethod? {
        get {
            return mockDefaultPaymentMethod
        }
        set {
            mockDefaultPaymentMethod = newValue
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

class MockKeyProvider: NSObject, STPCustomerEphemeralKeyProvider {
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        completion(nil, NSError.stp_ephemeralKeyDecodingError())
    }
}

class MockCustomerContext: STPCustomerContext {

    let customer = MockCustomer()

    override func retrieveCustomer(_ completion: STPCustomerCompletionBlock? = nil) {
        if let completion = completion {
            completion(customer, nil)
        }
    }

    override func attachPaymentMethod(toCustomer paymentMethod: STPPaymentMethod, completion: STPErrorBlock? = nil) {
        customer.paymentMethods.append(paymentMethod)
        if let completion = completion {
            completion(nil)
        }
    }

    override func detachPaymentMethod(fromCustomer paymentMethod: STPPaymentMethod, completion: STPErrorBlock? = nil) {
        if let index = customer.paymentMethods.firstIndex(where: { $0.stripeId == paymentMethod.stripeId }) {
            customer.paymentMethods.remove(at: index)
        }
        if let completion = completion {
            completion(nil)
        }
    }

    override func listPaymentMethodsForCustomer(completion: STPPaymentMethodsCompletionBlock? = nil) {
        if let completion = completion {
            completion(customer.paymentMethods, nil)
        }
    }

    func selectDefaultCustomerPaymentMethod(_ paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock) {
        if customer.paymentMethods.contains(where: { $0.stripeId == paymentMethod.stripeId }) {
            customer.defaultPaymentMethod = paymentMethod
        }
        completion(nil)
    }

    override func updateCustomer(withShippingAddress shipping: STPAddress, completion: STPErrorBlock?) {
        customer.shippingAddress = shipping
        if let completion = completion {
            completion(nil)
        }
    }

    override func retrieveLastSelectedPaymentMethodIDForCustomer(completion: @escaping (String?, Error?) -> Void) {
        completion(nil, nil)
    }
    override func saveLastSelectedPaymentMethodID(forCustomer paymentMethodID: String?, completion: STPErrorBlock?) {
        if let completion = completion {
            completion(nil)
        }
    }
}
