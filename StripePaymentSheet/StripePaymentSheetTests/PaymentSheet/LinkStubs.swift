//
//  LinkStubs.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

struct LinkStubs {
    private init() {}
}

extension LinkStubs {

    struct PaymentMethodIndices {
        static let card = 0
        static let cardWithFailingChecks = 1
        static let bankAccount = 2
        static let expiredCard = 3
        static let unknownWithDisplay = 4
        static let notExisting = -1
    }

    static func paymentMethods() -> [ConsumerPaymentDetails] {
        return [
            ConsumerPaymentDetails(
                stripeID: "1",
                details: .card(card: .init(
                    expiryYear: 30,
                    expiryMonth: 10,
                    brand: "visa",
                    networks: ["visa"],
                    last4: "1234",
                    funding: .debit,
                    checks: nil)
                ),
                billingAddress: nil,
                billingEmailAddress: nil,
                nickname: nil,
                isDefault: true
            ),
            ConsumerPaymentDetails(
                stripeID: "2",
                details: .card(card: .init(
                    expiryYear: 30,
                    expiryMonth: 10,
                    brand: "mastercard",
                    networks: ["mastercard"],
                    last4: "4321",
                    funding: .credit,
                    checks: .init(cvcCheck: .fail))
                ),
                billingAddress: nil,
                billingEmailAddress: nil,
                nickname: nil,
                isDefault: false
            ),
            ConsumerPaymentDetails(
                stripeID: "3",
                details: .bankAccount(bankAccount: .init(iconCode: nil, name: "test", last4: "1234", country: "COUNTRY_US")),
                billingAddress: nil,
                billingEmailAddress: nil,
                nickname: "Patrick's bank",
                isDefault: false
            ),
            ConsumerPaymentDetails(
                stripeID: "4",
                details: .card(card: .init(
                    expiryYear: 20,
                    expiryMonth: 10,
                    brand: "discover",
                    networks: ["discover"],
                    last4: "1111",
                    funding: .prepaid,
                    checks: nil)
                ),
                billingAddress: nil,
                billingEmailAddress: nil,
                nickname: "Patrick's card",
                isDefault: false
            ),
            ConsumerPaymentDetails(
                stripeID: "5",
                details: .unparsable(rawValue: "CRYPTO"),
                billingAddress: nil,
                billingEmailAddress: nil,
                nickname: nil,
                display: .init(label: "Stablecoin", sublabel: "Wallet •••2", icon: nil),
                isDefault: false
            ),
        ]
    }

    static func consumerSession(supportedPaymentDetailsTypes: Set<ParsedEnum<ConsumerPaymentDetails.DetailsType>> = [ParsedEnum(.card), ParsedEnum(.bankAccount), ParsedEnum(rawValue: "CRYPTO")]) -> ConsumerSession {
        return ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "user@example.com",
            redactedFormattedPhoneNumber: "(***) *** **55",
            unredactedPhoneNumber: "(555) 555-5555",
            phoneNumberCountry: "US",
            verificationSessions: [],
            supportedPaymentDetailsTypes: supportedPaymentDetailsTypes,
            mobileFallbackWebviewParams: nil
        )
    }

    static func shippingAddresses() -> [ShippingAddressesResponse.ShippingAddress] {
        return [
            makeShippingAddress(
                id: "saddr_1",
                name: "Foo Bar",
                line1: "354 Oyster Point Blvd",
                locality: "South San Francisco",
                administrativeArea: "CA",
                postalCode: "94080",
                countryCode: "US",
                isDefault: true
            ),
            makeShippingAddress(
                id: "saddr_2",
                name: "Mat Schmid",
                line1: "98 Flora St",
                locality: "Ottawa",
                administrativeArea: "ON",
                postalCode: "K2P1A8",
                countryCode: "CA",
                isDefault: false
            ),
        ]
    }

    private static func makeShippingAddress(
        id: String,
        name: String? = nil,
        line1: String? = nil,
        line2: String? = nil,
        locality: String? = nil,
        administrativeArea: String? = nil,
        postalCode: String? = nil,
        countryCode: String? = nil,
        isDefault: Bool = false
    ) -> ShippingAddressesResponse.ShippingAddress {
        var addressJSON: [String: Any] = [:]
        if let name { addressJSON["name"] = name }
        if let line1 { addressJSON["line_1"] = line1 }
        if let line2 { addressJSON["line_2"] = line2 }
        if let locality { addressJSON["locality"] = locality }
        if let administrativeArea { addressJSON["administrative_area"] = administrativeArea }
        if let postalCode { addressJSON["postal_code"] = postalCode }
        if let countryCode { addressJSON["country_code"] = countryCode }

        let payload: [String: Any] = [
            "id": id,
            "is_default": isDefault,
            "address": addressJSON,
        ]
        let data = try! JSONSerialization.data(withJSONObject: payload)
        return try! JSONDecoder().decode(ShippingAddressesResponse.ShippingAddress.self, from: data)
    }

    static func account(
        email: String = "user@example.com",
        session: ConsumerSession? = Self.consumerSession()
    ) -> PaymentSheetLinkAccount {
        .init(
            email: email,
            session: session,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )
    }

}
