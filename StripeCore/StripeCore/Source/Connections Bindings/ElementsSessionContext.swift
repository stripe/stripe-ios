//
//  ElementsSessionContext.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-25.
//

import Foundation

/// Contains elements session context useful for the Financial Connections SDK.
@_spi(STP) public struct ElementsSessionContext {
    @_spi(STP) @frozen public enum IntentID {
        case payment(String)
        case setup(String)
    }

    /// These fields will be used to prefill the Financial Connections Link Login pane.
    /// An unformatted phone number + country code will be passed to the web flow,
    /// and a formatted phone number will be passed to the native flow.
    @_spi(STP) public struct PrefillDetails {
        @_spi(STP) public let email: String?
        @_spi(STP) public let formattedPhoneNumber: String?
        @_spi(STP) public let unformattedPhoneNumber: String?
        @_spi(STP) public let countryCode: String?

        @_spi(STP) public init(
            email: String?,
            formattedPhoneNumber: String?,
            unformattedPhoneNumber: String?,
            countryCode: String?
        ) {
            self.email = email
            self.formattedPhoneNumber = formattedPhoneNumber
            self.unformattedPhoneNumber = unformattedPhoneNumber
            self.countryCode = countryCode
        }
    }

    @_spi(STP) public let amount: Int?
    @_spi(STP) public let currency: String?
    @_spi(STP) public let prefillDetails: PrefillDetails?
    @_spi(STP) public let intentId: IntentID?
    @_spi(STP) public let linkMode: LinkMode?
    @_spi(STP) public let billingAddress: BillingAddress?

    @_spi(STP) public init(
        amount: Int?,
        currency: String?,
        prefillDetails: PrefillDetails?,
        intentId: IntentID?,
        linkMode: LinkMode?,
        billingAddress: BillingAddress?
    ) {
        self.amount = amount
        self.currency = currency
        self.prefillDetails = prefillDetails
        self.intentId = intentId
        self.linkMode = linkMode
        self.billingAddress = billingAddress
    }
}

@_spi(STP) public extension ElementsSessionContext {
    /// https://docs.stripe.com/api/payment_methods/create#create_payment_method-billing_details
    struct BillingDetails: Encodable {
        struct Address: Encodable {
            let city: String?
            let country: String?
            let line1: String?
            let line2: String?
            let postalCode: String?
            let state: String?

            init?(
                city: String?,
                country: String?,
                line1: String?,
                line2: String?,
                postalCode: String?,
                state: String?
            ) {
                guard city != nil || country != nil || line1 != nil || line2 != nil || postalCode != nil || state != nil else {
                    return nil
                }

                self.city = city
                self.country = country
                self.line1 = line1
                self.line2 = line2
                self.postalCode = postalCode
                self.state = state
            }

            enum CodingKeys: String, CodingKey {
                case city
                case country
                case line1
                case line2
                case postalCode = "postal_code"
                case state
            }

            func encode(to encoder: any Encoder) throws {
                var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeIfNotEmpty(self.city, forKey: .city)
                try container.encodeIfNotEmpty(self.country, forKey: .country)
                try container.encodeIfNotEmpty(self.line1, forKey: .line1)
                try container.encodeIfNotEmpty(self.line2, forKey: .line2)
                try container.encodeIfNotEmpty(self.postalCode, forKey: .postalCode)
                try container.encodeIfNotEmpty(self.state, forKey: .state)
            }
        }

        let name: String?
        let email: String?
        let phone: String?
        let address: Address?

        enum CodingKeys: CodingKey {
            case name
            case email
            case phone
            case address
        }

        @_spi(STP) public func encode(to encoder: any Encoder) throws {
            var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfNotEmpty(self.name, forKey: .name)
            try container.encodeIfNotEmpty(self.email, forKey: .email)
            try container.encodeIfNotEmpty(self.phone, forKey: .phone)
            try container.encodeIfPresent(self.address, forKey: .address)
        }
    }

    var billingDetails: BillingDetails {
        BillingDetails(
            name: billingAddress?.name,
            email: prefillDetails?.email,
            phone: prefillDetails?.formattedPhoneNumber,
            address: BillingDetails.Address(
                city: billingAddress?.city,
                country: billingAddress?.countryCode,
                line1: billingAddress?.line1,
                line2: billingAddress?.line2,
                postalCode: billingAddress?.postalCode,
                state: billingAddress?.state
            )
        )
    }
}
