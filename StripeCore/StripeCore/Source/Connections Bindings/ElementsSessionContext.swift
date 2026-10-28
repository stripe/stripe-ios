//
//  ElementsSessionContext.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-25.
//

import Foundation

/// Contains elements session context useful for the Financial Connections SDK.
@_spi(InternalOnlyAPI) public struct ElementsSessionContext {
    @_spi(InternalOnlyAPI) @frozen public enum IntentID {
        case payment(String)
        case setup(String)
        case deferred(String)

        @_spi(InternalOnlyAPI) public var id: String {
            switch self {
            case let .payment(id), let .setup(id), let .deferred(id):
                return id
            }
        }
    }

    @_spi(InternalOnlyAPI) public struct LinkSettings {
        @_spi(InternalOnlyAPI) public let useAttestationEndpoints: Bool?
        @_spi(InternalOnlyAPI) public let brand: LinkBrand?

        @_spi(InternalOnlyAPI) public init(useAttestationEndpoints: Bool?, brand: LinkBrand? = nil) {
            self.useAttestationEndpoints = useAttestationEndpoints
            self.brand = brand
        }
    }

    /// These fields will be used to prefill the Financial Connections Link Login pane.
    /// An unformatted phone number + country code will be passed to the web flow,
    /// and a formatted phone number will be passed to the native flow.
    @_spi(InternalOnlyAPI) public struct PrefillDetails {
        @_spi(InternalOnlyAPI) public let email: String?
        @_spi(InternalOnlyAPI) public let formattedPhoneNumber: String?
        @_spi(InternalOnlyAPI) public let unformattedPhoneNumber: String?
        @_spi(InternalOnlyAPI) public let countryCode: String?

        @_spi(InternalOnlyAPI) public init(
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

    @_spi(InternalOnlyAPI) public let amount: Int?
    @_spi(InternalOnlyAPI) public let currency: String?
    @_spi(InternalOnlyAPI) public let prefillDetails: PrefillDetails?
    @_spi(InternalOnlyAPI) public let intentId: IntentID?
    @_spi(InternalOnlyAPI) public let linkMode: LinkMode?
    @_spi(InternalOnlyAPI) public let billingDetails: BillingDetails?
    @_spi(InternalOnlyAPI) public let eligibleForIncentive: Bool
    @_spi(InternalOnlyAPI) public let allowRedisplay: String?
    @_spi(InternalOnlyAPI) public let linkSettings: LinkSettings?
    @_spi(InternalOnlyAPI) public let clientAttributionMetadata: STPClientAttributionMetadata?

    @_spi(InternalOnlyAPI) public var billingAddress: BillingAddress? {
        BillingAddress(from: billingDetails)
    }

    @_spi(InternalOnlyAPI) public var incentiveEligibilitySession: IntentID? {
        guard eligibleForIncentive else {
            return nil
        }
        return intentId
    }

    @_spi(InternalOnlyAPI) public init(
        amount: Int? = nil,
        currency: String? = nil,
        prefillDetails: PrefillDetails? = nil,
        intentId: IntentID? = nil,
        linkMode: LinkMode? = nil,
        billingDetails: BillingDetails? = nil,
        eligibleForIncentive: Bool = false,
        allowRedisplay: String? = nil,
        linkSettings: LinkSettings? = nil,
        clientAttributionMetadata: STPClientAttributionMetadata? = nil
    ) {
        self.amount = amount
        self.currency = currency
        self.prefillDetails = prefillDetails
        self.intentId = intentId
        self.linkMode = linkMode
        self.billingDetails = billingDetails
        self.eligibleForIncentive = eligibleForIncentive
        self.allowRedisplay = allowRedisplay
        self.linkSettings = linkSettings
        self.clientAttributionMetadata = clientAttributionMetadata
    }
}

@_spi(InternalOnlyAPI) public extension ElementsSessionContext {
    /// https://docs.stripe.com/api/payment_methods/create#create_payment_method-billing_details
    struct BillingDetails: Encodable {
        @_spi(InternalOnlyAPI) public struct Address: Encodable {
            @_spi(InternalOnlyAPI) public let city: String?
            @_spi(InternalOnlyAPI) public let country: String?
            @_spi(InternalOnlyAPI) public let line1: String?
            @_spi(InternalOnlyAPI) public let line2: String?
            @_spi(InternalOnlyAPI) public let postalCode: String?
            @_spi(InternalOnlyAPI) public let state: String?

            @_spi(InternalOnlyAPI) public init?(
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

            @_spi(InternalOnlyAPI) public func encode(to encoder: any Encoder) throws {
                var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeIfNotEmpty(self.city, forKey: .city)
                try container.encodeIfNotEmpty(self.country, forKey: .country)
                try container.encodeIfNotEmpty(self.line1, forKey: .line1)
                try container.encodeIfNotEmpty(self.line2, forKey: .line2)
                try container.encodeIfNotEmpty(self.postalCode, forKey: .postalCode)
                try container.encodeIfNotEmpty(self.state, forKey: .state)
            }
        }

        @_spi(InternalOnlyAPI) public let name: String?
        @_spi(InternalOnlyAPI) public let email: String?
        @_spi(InternalOnlyAPI) public let phone: String?
        @_spi(InternalOnlyAPI) public let address: Address?

        @_spi(InternalOnlyAPI) public init(name: String?, email: String?, phone: String?, address: Address?) {
            self.name = name
            self.email = email
            self.phone = phone
            self.address = address
        }

        enum CodingKeys: CodingKey {
            case name
            case email
            case phone
            case address
        }

        @_spi(InternalOnlyAPI) public func encode(to encoder: any Encoder) throws {
            var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfNotEmpty(self.name, forKey: .name)
            try container.encodeIfNotEmpty(self.email, forKey: .email)
            try container.encodeIfNotEmpty(self.phone, forKey: .phone)
            try container.encodeIfPresent(self.address, forKey: .address)
        }
    }
}
