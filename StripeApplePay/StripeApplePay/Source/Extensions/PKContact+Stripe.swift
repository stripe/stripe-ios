//
//  PKContact+Stripe.swift
//  StripeApplePay
//
//  Created by David Estes on 11/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

extension PKContact {
    @_spi(STP) public var addressParams: [AnyHashable: Any] {
        var params: [AnyHashable: Any] = [:]
        let stpAddress = StripeContact(pkContact: self)

        params["name"] = stpAddress.name
        params["address_line1"] = stpAddress.line1
        params["address_city"] = stpAddress.city
        params["address_state"] = stpAddress.state
        params["address_zip"] = stpAddress.postalCode
        params["address_country"] = stpAddress.country

        return params
    }
}
