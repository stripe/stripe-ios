//
//  STPPaymentMethodListDeserializer.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 5/16/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Deserializes the response returned from https://stripe.com/docs/api/payment_methods/list
@_spi(STP) public class STPPaymentMethodListDeserializer: NSObject, STPAPIResponseDecodable {
    @_spi(STP) public var paymentMethods: [STPPaymentMethod]?
    @_spi(STP) public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: STPAPIResponseDecodable
    override required init() {
        super.init()
    }

    @_spi(STP) public class func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()
        // Required fields
        guard let data = dict.stp_array(forKey: "data") as? [[AnyHashable: Any]] else {
            return nil
        }

        let paymentMethodsDeserializer = self.init()
        var paymentMethods: [STPPaymentMethod] = []
        for paymentMethodJSON in data {
            let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethodJSON)
            if let paymentMethod = paymentMethod {
                paymentMethods.append(paymentMethod)
            }
        }
        paymentMethodsDeserializer.paymentMethods = paymentMethods
        return paymentMethodsDeserializer
    }
}
