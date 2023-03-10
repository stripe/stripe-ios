//
//  STPSwiftFixtures.swift
//  StripeiOS Tests
//
//  Created by David Estes on 10/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class MockEphemeralKeyProvider: NSObject, STPCustomerEphemeralKeyProvider {
    func createCustomerKey(
        withAPIVersion apiVersion: String,
        completion: @escaping STPJSONResponseCompletionBlock
    ) {
        completion(STPFixtures.ephemeralKey().allResponseFields, nil)
    }
}

@objcMembers
@objc class Testing_StaticCustomerContext_Objc: Testing_StaticCustomerContext {

}

@objcMembers
class Testing_StaticCustomerContext: STPCustomerContext {
    var customer: STPCustomer
    var paymentMethods: [STPPaymentMethod]
    convenience init() {
        let customer = STPFixtures.customerWithSingleCardTokenSource()
        let paymentMethods = [STPFixtures.paymentMethod()].compactMap { $0 }
        self.init(
            customer: customer,
            paymentMethods: paymentMethods
        )
    }
    init(
        customer: STPCustomer,
        paymentMethods: [STPPaymentMethod]
    ) {
        self.customer = customer
        self.paymentMethods = paymentMethods
        super.init(
            keyManager: STPEphemeralKeyManager(
                keyProvider: MockEphemeralKeyProvider(),
                apiVersion: "1",
                performsEagerFetching: false
            ),
            apiClient: STPAPIClient.shared
        )
    }

    override func retrieveCustomer(_ completion: STPCustomerCompletionBlock?) {
        if let completion = completion {
            completion(customer, nil)
        }
    }

    override func listPaymentMethodsForCustomer(completion: STPPaymentMethodsCompletionBlock?) {
        if let completion = completion {
            completion(paymentMethods, nil)
        }
    }

    var didAttach = false
    override func attachPaymentMethod(
        toCustomer paymentMethod: STPPaymentMethod,
        completion: STPErrorBlock?
    ) {
        didAttach = true
        if let completion = completion {
            completion(nil)
        }
    }

    override func retrieveLastSelectedPaymentMethodIDForCustomer(
        completion: @escaping (String?, Error?) -> Void
    ) {
        completion(nil, nil)
    }
}
