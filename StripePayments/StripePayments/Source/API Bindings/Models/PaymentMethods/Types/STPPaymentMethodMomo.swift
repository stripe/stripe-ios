//
//  STPPaymentMethodMomo.swift
//  StripePayments
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// A MoMo Payment Method.
/// - seealso: https://docs.stripe.com/payments/momo/accept-a-payment?payment-ui=direct-api
public class STPPaymentMethodMomo: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodMomo.self), self)
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    /// :nodoc:
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response else {
            return nil
        }
        return self.init(dictionary: response)
    }

    required init(dictionary: [AnyHashable: Any]) {
        super.init()
        allResponseFields = dictionary
    }
}
