//
//  STPPaymentMethodTouchNGo.swift
//  StripePayments
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// A Touch 'n Go Payment Method.
/// - seealso: https://docs.stripe.com/payments/touch-n-go/accept-a-payment?payment-ui=direct-api
public class STPPaymentMethodTouchNGo: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodTouchNGo.self), self)
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    /// :nodoc:
    @objc public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
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
