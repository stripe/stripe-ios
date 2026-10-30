//
//  LinkAccountSession.swift
//  StripePayments
//
//  Created by Cameron Sabol on 10/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/// For internal SDK use only
@_spi(InternalOnlyAPI) public class LinkAccountSession: NSObject, STPAPIResponseDecodable {
    @_spi(InternalOnlyAPI) public let stripeID: String
    @_spi(InternalOnlyAPI) public let livemode: Bool
    @_spi(InternalOnlyAPI) public let clientSecret: String
    @_spi(InternalOnlyAPI) public let permissions: [String]

    @_spi(InternalOnlyAPI) public let allResponseFields: [AnyHashable: Any]

    @_spi(InternalOnlyAPI) public required init(
        stripeID: String,
        livemode: Bool,
        clientSecret: String,
        permissions: [String] = [],
        allResponseFields: [AnyHashable: Any]
    ) {
        self.stripeID = stripeID
        self.livemode = livemode
        self.clientSecret = clientSecret
        self.permissions = permissions
        self.allResponseFields = allResponseFields
        super.init()
    }

    @_spi(InternalOnlyAPI) public static func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        guard let response = response,
            let stripeID = response["id"] as? String,
            let livemode = response["livemode"] as? Bool,
            let clientSecret = response["client_secret"] as? String
        else {
            return nil
        }

        return LinkAccountSession(
            stripeID: stripeID,
            livemode: livemode,
            clientSecret: clientSecret,
            permissions: response["permissions"] as? [String] ?? [],
            allResponseFields: response
        ) as? Self
    }
}
