// Copyright © 2026 Stripe, Inc. All rights reserved.

import Foundation

/// A PayTo PaymentMethod.
public class STPPaymentMethodPayto: NSObject, STPAPIResponseDecodable {
    public private(set) var allResponseFields: [AnyHashable: Any] = [:]
    /// The bank account's fingerprint.
    @objc public private(set) var fingerprint: String?
    /// The last four digits of the bank account.
    @objc public private(set) var last4: String?
    /// The Australian bank and branch code.
    @objc public private(set) var bsbNumber: String?
    /// The PayID used to identify the bank account.
    @objc public private(set) var payId: String?

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response else { return nil }
        return self.init(dictionary: response)
    }

    required init(dictionary: [AnyHashable: Any]) {
        super.init()
        allResponseFields = dictionary
        fingerprint = dictionary["fingerprint"] as? String
        last4 = dictionary["last4"] as? String
        bsbNumber = dictionary["bsb_number"] as? String
        payId = dictionary["pay_id"] as? String
    }
}
