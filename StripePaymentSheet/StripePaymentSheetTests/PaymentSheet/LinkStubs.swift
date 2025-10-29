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
@testable@_spi(STP) import StripePayments

struct LinkStubs {
    private init() {}
}

extension LinkStubs {

    struct PaymentMethodIndices {
        static let card = 0
        static let cardWithFailingChecks = 1
        static let bankAccount = 2
        static let expiredCard = 3
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
        ]
    }

    static func consumerSession(supportedPaymentDetailsTypes: Set<ConsumerPaymentDetails.DetailsType> = [.card, .bankAccount]) -> ConsumerSession {
        return ConsumerSession(
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
