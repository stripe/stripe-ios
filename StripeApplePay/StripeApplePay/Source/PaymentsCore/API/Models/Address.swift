//
//  Address.swift
//  StripeApplePay
//
//  Created by David Estes on 8/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// An internal struct for handling contacts. This is not encodable/decodable for use with the Stripe API.
struct StripeContact {
    /// The user's full name (e.g. "Jane Doe")
    public var name: String?

    /// The first line of the user's street address (e.g. "123 Fake St")
    public var line1: String?

    /// The apartment, floor number, etc of the user's street address (e.g. "Apartment 1A")
    public var line2: String?

    /// The city in which the user resides (e.g. "San Francisco")
    public var city: String?

    /// The state in which the user resides (e.g. "CA")
    public var state: String?

    /// The postal code in which the user resides (e.g. "90210")
    public var postalCode: String?

    /// The ISO country code of the address (e.g. "US")
    public var country: String?

    /// The phone number of the address (e.g. "8885551212")
    public var phone: String?

    /// The email of the address (e.g. "jane@doe.com")
    public var email: String?

    internal var givenName: String?
    internal var familyName: String?
}
