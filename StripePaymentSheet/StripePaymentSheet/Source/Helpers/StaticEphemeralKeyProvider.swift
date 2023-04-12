//
//  StaticEphemeralKeyProvider.swift
//  StripePaymentSheet
//
//  Created by David Estes on 3/13/23.
//

import Foundation
import StripePaymentsUI

public extension STPCustomerContext {
    /// Initializes a new `STPCustomerContext` with the specified key provider.
    /// This is not recommended, use initWithKeyProvider and an STPCustomerEphemeralKeyProvider instead.
    /// The key will expire after 60 minutes.
    /// - Parameter keyProvider:   The key provider the customer context will use.
    /// - Returns: the newly-instantiated customer context.
    convenience init(
        customerId: String,
        ephemeralKeySecret: String
    ) {
        let keyProvider = StaticEphemeralKeyProvider(customerId: customerId, ephemeralKeySecret: ephemeralKeySecret)
        self.init(keyProvider: keyProvider, apiClient: STPAPIClient.shared)
    }
}

class StaticEphemeralKeyProvider: NSObject, STPCustomerEphemeralKeyProvider {
    let customerId: String
    let ephemeralKeySecret: String
    // This is a bridge between the STPCustomerEphemeralKeyProvider and the way PaymentSheet requests keys.
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping StripePayments.STPJSONResponseCompletionBlock) {
        let responseDict: [String: Any] = [
            "id": customerId,
            "created": Date.distantFuture.timeIntervalSince1970,
            "secret": ephemeralKeySecret,
            "expires": Date.distantFuture.timeIntervalSince1970,
            "associated_objects": [["type": "customer", "id": customerId]],
            "livemode": []
        ]
        completion(responseDict, nil)
    }
    
    init(customerId: String, ephemeralKeySecret: String) {
        self.customerId = customerId
        self.ephemeralKeySecret = ephemeralKeySecret
    }
}
