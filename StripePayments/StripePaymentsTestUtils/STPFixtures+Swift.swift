//
//  STPFixtures+Swift.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 3/22/23.
//

import Foundation
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments

public extension STPFixtures {
    static func paymentMethodBillingDetails() -> STPPaymentMethodBillingDetails {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.email = "foo@bar.com"
        billingDetails.phone = "5555555555"
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.line1 = "510 Townsend St."
        billingDetails.address?.line2 = "Line 2"
        billingDetails.address?.city = "San Francisco"
        billingDetails.address?.state = "CA"
        billingDetails.address?.country = "US"
        billingDetails.address?.postalCode = "94102"
        return billingDetails
    }

    static func paymentIntent(
        paymentMethodTypes: [String],
        setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none,
        paymentMethodOptionsSetupFutureUsage: [STPPaymentMethodType: String]? = nil,
        currency: String = "usd",
        status: STPPaymentIntentStatus = .requiresPaymentMethod,
        paymentMethod: [AnyHashable: Any]? = nil,
        nextAction: STPIntentActionType? = nil
    ) -> STPPaymentIntent {
        var apiResponse: [AnyHashable: Any] = [
            "id": "123",
            "client_secret": "sec",
            "amount": 2345,
            "currency": currency,
            "status": STPPaymentIntentStatus.string(from: status),
            "livemode": false,
            "created": 1652736692.0,
            "payment_method_types": paymentMethodTypes,
        ]
        if let setupFutureUsage = setupFutureUsage.stringValue {
            apiResponse["setup_future_usage"] = setupFutureUsage
        }
        if let paymentMethodOptionsSetupFutureUsage = paymentMethodOptionsSetupFutureUsage {
            var paymentMethodOptions: [String: Any] = [:]
            paymentMethodOptionsSetupFutureUsage.forEach { paymentMethodType, setupFutureUsage in
                paymentMethodOptions[paymentMethodType.identifier] = ["setup_future_usage": setupFutureUsage]
            }
            apiResponse["payment_method_options"] = paymentMethodOptions
        }
        if let paymentMethod = paymentMethod {
            apiResponse["payment_method"] = paymentMethod
        }
        if let nextAction = nextAction {
            apiResponse["next_action"] = ["type": nextAction.stringValue]
        }
        return STPPaymentIntent.decodedObject(fromAPIResponse: apiResponse)!
    }

    static func setupIntent(
        paymentMethodTypes: [String],
        status: STPSetupIntentStatus = .requiresPaymentMethod,
        paymentMethod: [AnyHashable: Any]? = nil,
        nextAction: STPIntentActionType? = nil
    ) -> STPSetupIntent {
        var apiResponse: [AnyHashable: Any] = [
            "id": "123",
            "client_secret": "sec",
            "status": STPSetupIntentStatus.string(from: status),
            "livemode": false,
            "created": 1652736692.0,
            "payment_method_types": paymentMethodTypes,
        ]

        if let paymentMethod = paymentMethod {
            apiResponse["payment_method"] = paymentMethod
        }
        if let nextAction = nextAction {
            apiResponse["next_action"] = ["type": nextAction.stringValue]
        }
        return STPSetupIntent.decodedObject(fromAPIResponse: apiResponse)!
    }

    static func usBankAccountPaymentMethod(bankName: String? = nil) -> STPPaymentMethod {
        var json = STPTestUtils.jsonNamed("USBankAccountPaymentMethod") as? [String: Any]
        if let bankName = bankName {
            var usBankAccountData = json?["us_bank_account"] as? [String: Any]
            usBankAccountData?["bank_name"] = bankName
            json?["us_bank_account"] = usBankAccountData
        }
        return STPPaymentMethod.decodedObject(fromAPIResponse: json)!
    }

    static func sepaDebitPaymentMethod() -> STPPaymentMethod {
        let json = STPTestUtils.jsonNamed("SEPADebitPaymentMethod")
        return STPPaymentMethod.decodedObject(fromAPIResponse: json)!
    }
}

public extension STPPaymentMethodParams {
    static func _testValidCardValue() -> STPPaymentMethodParams {
        return _testCardValue()
    }

    static func _testCardValue(number: String = "4242424242424242", email: String? = nil) -> STPPaymentMethodParams {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = number
        cardParams.cvc = "123"
        cardParams.expYear = 2040
        cardParams.expMonth = 01
        let billingDetails: STPPaymentMethodBillingDetails? = {
            guard let email else { return nil }
            let details = STPPaymentMethodBillingDetails()
            details.email = email
            return details
        }()
        return STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
    }

    static func _testSEPA() -> STPPaymentMethodParams {
        let sepaDebitParams = STPPaymentMethodSEPADebitParams()
        sepaDebitParams.iban =  "AT611904300234573201"

        let billingAddress = STPPaymentMethodAddress()
        billingAddress.city = "London"
        billingAddress.country = "GB"
        billingAddress.line1 = "Stripe, 7th Floor The Bower Warehouse"
        billingAddress.postalCode = "EC1V 9NR"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = billingAddress
        billingDetails.email = "email@email.com"
        billingDetails.name = "Isaac Asimov"
        billingDetails.phone = "555-555-5555"

        return STPPaymentMethodParams(sepaDebit: sepaDebitParams, billingDetails: billingDetails, metadata: nil)
    }

    static func _testUSBankAccountValue(name: String? = nil, email: String? = nil) -> STPPaymentMethodParams {
        let usBankAccount = STPPaymentMethodUSBankAccountParams()
        usBankAccount.accountNumber = "000123456789"
        usBankAccount.routingNumber = "110000000"
        usBankAccount.accountType = .checking
        usBankAccount.accountHolderType = .individual

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = name
        billingDetails.email = email

        return STPPaymentMethodParams(usBankAccount: usBankAccount, billingDetails: billingDetails, metadata: nil)
    }
}

public extension STPPaymentMethod {
    static let _testCardJSON = [
        "id": "pm_123card",
        "type": "card",
        "created": "12345",
        "card": [
            "last4": "4242",
            "brand": "visa",
            "fingerprint": "B8XXs2y2JsVBtB9f",
            "networks": ["available": ["visa"]],
            "exp_month": "01",
            "exp_year": "2040",
        ],
    ] as [String: Any]

    static func _testCard() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: _testCardJSON)!
    }
    static func _testCard(line1: String? = nil,
                          line2: String? = nil,
                          city: String? = nil,
                          state: String? = nil,
                          postalCode: String? = nil,
                          countryCode: String? = nil) -> STPPaymentMethod {
        var address: [String: String] = [:]
        if let line1 {
            address["line1"] = line1
        }
        if let line2 {
            address["line2"] = line2
        }
        if let city {
            address["city"] = city
        }
        if let state {
            address["state"] = state
        }
        if let postalCode {
            address["postal_code"] = postalCode
        }
        if let countryCode {
            address["country"] = countryCode
        }
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123card",
            "type": "card",
            "created": "12345",
            "card": [
                "last4": "4242",
                "brand": "visa",
                "fingerprint": "B8XXs2y2JsVBtB9f",
                "networks": ["available": ["visa"]],
                "exp_month": "01",
                "exp_year": "2040",
            ],
            "billing_details": [
                "address": address,
            ],
        ])!
    }
    static func _testCardAmex() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123card",
            "type": "card",
            "created": "12345",
            "card": [
                "last4": "0005",
                "brand": "amex",
            ],
        ])!
    }

    static func _testCardCoBranded(brand: String = "visa", displayBrand: String? = nil, networks: [String] = ["visa", "amex"]) -> STPPaymentMethod {
        var apiResponse: [String: Any] = [
            "id": "pm_123card",
            "type": "card",
            "created": "12345",
            "card": [
                "last4": "4242",
                "brand": brand,
                "networks": ["available": networks],
                "exp_month": "01",
                "exp_year": "2040",
            ],
        ]
        if let displayBrand {
            apiResponse[jsonDict: "card"]?["display_brand"] = displayBrand
        }
        return STPPaymentMethod.decodedObject(fromAPIResponse: apiResponse)!
    }

    static func _testUSBankAccount() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123",
            "type": "us_bank_account",
            "created": "12345",
            "us_bank_account": [
                "account_holder_type": "individual",
                "account_type": "checking",
                "bank_name": "STRIPE TEST BANK",
                "fingerprint": "ickfX9sbxIyAlbuh",
                "last4": "6789",
                "networks": [
                  "preferred": "ach",
                  "supported": [
                    "ach",
                  ],
                ] as [String: Any],
                "routing_number": "110000000",
            ] as [String: Any],
            "billing_details": [
                "name": "Sam Stripe",
                "email": "sam@stripe.com",
            ] as [String: Any],
        ])!
    }

    static func _testSEPA() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123",
            "type": "sepa_debit",
            "created": "12345",
            "sepa_debit": [
                "last4": "1234",
            ],
            "billing_details": [
                "name": "Sam Stripe",
                "email": "sam@stripe.com",
            ] as [String: Any],
        ])!
    }

    static func _testLink(displayName: String? = nil) -> STPPaymentMethod {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123",
            "type": "link",
            "created": "12345",
            "sepa_debit": [
                "last4": "1234",
            ],
            "billing_details": [
                "name": "Sam Stripe",
                "email": "sam@stripe.com",
            ] as [String: Any],
        ])!
        paymentMethod.linkPaymentDetails = .card(
            LinkPaymentDetails.Card(
                id: "csmr_123",
                displayName: displayName,
                expMonth: 12,
                expYear: 2030,
                last4: "4242",
                brand: .visa
            )
        )
        return paymentMethod
    }

    static func _testCard(
        id: String = "pm_123",
        country: String? = "US"
    ) -> STPPaymentMethod {
        // Create mock payment method data that matches API response structure
        var mockData: [String: Any] = [
            "id": id,
            "object": "payment_method",
            "created": "12345",
            "type": "card",
            "card": [
                "brand": "visa",
                "last4": "4242",
                "exp_month": 12,
                "exp_year": 2025,
            ],
        ]

        if let country = country {
            mockData["billing_details"] = [
                "address": [
                    "country": country
                ],
            ]
        }

        return STPPaymentMethod.decodedObject(fromAPIResponse: mockData)!
    }
}
