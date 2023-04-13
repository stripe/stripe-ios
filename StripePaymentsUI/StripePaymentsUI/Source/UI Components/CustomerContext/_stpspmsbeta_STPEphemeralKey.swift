//
//  STPEphemeralKey.swift
//  StripeiOS
//
//  Created by Ben Guo on 5/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

@_spi(STP) public class _stpspmsbeta_STPEphemeralKey: NSObject, STPAPIResponseDecodable {
    private(set) var stripeID: String
    private(set) var created: Date
    private(set) var livemode = false
    @_spi(STP) public private(set) var secret: String
    private(set) var expires: Date
    private(set) var customerID: String?
    @_spi(STP) public private(set) var issuingCardID: String?

    /// You cannot directly instantiate an `STPEphemeralKey`. You should instead use
    /// `decodedObjectFromAPIResponse:` to create a key from a JSON response.
    required init(
        stripeID: String,
        created: Date,
        secret: String,
        expires: Date
    ) {
        self.stripeID = stripeID
        self.created = created
        self.secret = secret
        self.expires = expires
        super.init()
    }

    @_spi(STP) public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    @_spi(STP) public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        // required fields
        guard
            let stripeId = dict.stp_string(forKey: "id"),
            let created = dict.stp_date(forKey: "created"),
            let secret = dict.stp_string(forKey: "secret"),
            let expires = dict.stp_date(forKey: "expires"),
            let associatedObjects = dict.stp_array(forKey: "associated_objects"),
            dict["livemode"] != nil
        else {
            return nil
        }

        var customerID: String?
        var issuingCardID: String?
        for obj in associatedObjects {
            if let obj = obj as? [AnyHashable: Any] {
                let type = obj.stp_string(forKey: "type")
                if type == "customer" {
                    customerID = obj.stp_string(forKey: "id")
                }
                if type == "issuing.card" {
                    issuingCardID = obj.stp_string(forKey: "id")
                }
            }
        }
        if customerID == nil && issuingCardID == nil {
            return nil
        }
        let key = self.init(stripeID: stripeId, created: created, secret: secret, expires: expires)
        key.customerID = customerID
        key.issuingCardID = issuingCardID
        key.stripeID = stripeId
        key.livemode = dict.stp_bool(forKey: "livemode", or: true)
        key.created = created
        key.secret = secret
        key.expires = expires
        key.allResponseFields = response
        return key
    }

    @_spi(STP) public override var hash: Int {
        return stripeID.hash
    }

    @_spi(STP) public override func isEqual(_ object: Any?) -> Bool {
        if self === (object as? _stpspmsbeta_STPEphemeralKey) {
            return true
        }
        if object == nil || !(object is _stpspmsbeta_STPEphemeralKey) {
            return false
        }
        if let object = object as? _stpspmsbeta_STPEphemeralKey {
            return isEqual(to: object)
        }
        return false
    }

    func isEqual(to other: _stpspmsbeta_STPEphemeralKey) -> Bool {
        return stripeID == other.stripeID
    }
}
