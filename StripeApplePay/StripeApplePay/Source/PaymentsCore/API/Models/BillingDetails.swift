//
//  BillingDetails.swift
//  StripeApplePay
//
//  Created by David Estes on 7/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    /// Billing information associated with a `STPPaymentMethod` that may be used or required by particular types of payment methods.
    /// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-billing_details
    public struct BillingDetails: UnknownFieldsCodable {
        /// Billing address.
        public var address: Address?

        /// The billing address, a property sent in a PaymentMethod response
        public struct Address: UnknownFieldsCodable {
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

            public var _additionalParametersStorage: NonEncodableParameters?
            public var _allResponseFieldsStorage: NonEncodableParameters?
        }

        /// Email address.
        public var email: String?
        /// Full name.
        public var name: String?
        /// Billing phone number (including extension).
        public var phone: String?

        public var _additionalParametersStorage: NonEncodableParameters?
        public var _allResponseFieldsStorage: NonEncodableParameters?
    }

}

extension StripeAPI.BillingDetails.Address {
    init(
        contact: StripeContact
    ) {
        self.city = contact.city
        self.country = contact.country
        self.line1 = contact.line1
        self.line2 = contact.line2
        self.postalCode = contact.postalCode
        self.state = contact.state
    }
}
