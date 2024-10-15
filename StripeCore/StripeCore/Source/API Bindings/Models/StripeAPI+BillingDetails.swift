//
//  BillingDetails.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-10-15.
//

import Foundation

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

            public init(
                line1: String? = nil,
                line2: String? = nil,
                city: String? = nil,
                state: String? = nil,
                postalCode: String? = nil,
                country: String? = nil
            ) {
                self.line1 = line1
                self.line2 = line2
                self.city = city
                self.state = state
                self.postalCode = postalCode
                self.country = country
            }
        }

        /// Email address.
        public var email: String?
        /// Full name.
        public var name: String?
        /// Billing phone number (including extension).
        public var phone: String?

        public var _additionalParametersStorage: NonEncodableParameters?
        public var _allResponseFieldsStorage: NonEncodableParameters?

        public init(
            address: Address? = nil,
            email: String? = nil,
            name: String? = nil,
            phone: String? = nil
        ) {
            self.address = address
            self.email = email
            self.name = name
            self.phone = phone
        }
    }
}
