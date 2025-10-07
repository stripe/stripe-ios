//
//  PaymentSheetConfigurationTests.swift
//  StripePaymentSheetTests
//

import XCTest

@testable@_spi(STP) @_spi(CustomerSessionBetaAccess) import StripePaymentSheet

class PaymentSheetConfigurationTests: XCTestCase {
    func testIsUsingBillingAddressCollection_Default() {
        let configuration = PaymentSheet.Configuration()
        XCTAssertFalse(configuration.requiresBillingDetailCollection())
    }

    func testIsUsingBillingAddressCollection_address_never() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .never
        XCTAssertFalse(configuration.requiresBillingDetailCollection())
    }

    func testIsUsingBillingAddressCollection_address_full() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .full
        XCTAssert(configuration.requiresBillingDetailCollection())
    }

    func testIsUsingBillingAddressCollection_email_never() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        XCTAssertFalse(configuration.requiresBillingDetailCollection())
    }

    func testIsUsingBillingAddressCollection_email_full() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        XCTAssert(configuration.requiresBillingDetailCollection())
    }

    func testIsUsingBillingAddressCollection_name_never() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .never
        XCTAssertFalse(configuration.requiresBillingDetailCollection())
    }

    func testIsUsingBillingAddressCollection_name_full() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        XCTAssert(configuration.requiresBillingDetailCollection())
    }

    func testIsUsingBillingAddressCollection_phone_never() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.phone = .never
        XCTAssertFalse(configuration.requiresBillingDetailCollection())
    }

    func testIsUsingBillingAddressCollection_phone_full() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.phone = .always
        XCTAssert(configuration.requiresBillingDetailCollection())
    }

    func testSTPPaymentMethodBillingDetailsToPaymentSheetBillingDetails() {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.email = "janedoe@test.com"
        billingDetails.phone = "+18885551234"
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.line1 = "123 Main Street"
        billingDetails.address?.line2 = ""
        billingDetails.address?.city = "San Francisco"
        billingDetails.address?.state = "California"
        billingDetails.address?.country = "US"

        let psBillingDetails: PaymentSheet.BillingDetails = billingDetails.toPaymentSheetBillingDetails()

        XCTAssertEqual(psBillingDetails.name, "Jane Doe")
        XCTAssertEqual(psBillingDetails.email, "janedoe@test.com")
        XCTAssertEqual(psBillingDetails.phone, "+18885551234")
        XCTAssertEqual(psBillingDetails.phoneNumberForDisplay, "+1 (888) 555-1234")
        XCTAssertEqual(psBillingDetails.address.line1, "123 Main Street")
        XCTAssertEqual(psBillingDetails.address.line2, "")
        XCTAssertEqual(psBillingDetails.address.city, "San Francisco")
        XCTAssertEqual(psBillingDetails.address.state, "California")
        XCTAssertEqual(psBillingDetails.address.country, "US")
    }
    func testReturnsEphemeralKey() {
        let customerConfig = PaymentSheet.CustomerConfiguration(id: "cus_12345", ephemeralKeySecret: "ek_12345")
        let key = customerConfig.ephemeralKeySecret(basedOn: .emptyElementsSession)
        XCTAssertEqual(key, "ek_12345")
    }

    func testReturnsEphemeralKeyFromElements() {
        let customerConfig = PaymentSheet.CustomerConfiguration(id: "cus_12345", customerSessionClientSecret: "cuss_12345")
        let key = customerConfig.ephemeralKeySecret(basedOn: .elementsSessionWithCustomerSessionForPaymentSheet(apiKey: "ek_11223344"))
        XCTAssertEqual(key, "ek_11223344")
    }

    func testBillingDetailsCollectionConfiguration_allowedCountries_default() {
        let configuration = PaymentSheet.BillingDetailsCollectionConfiguration()
        XCTAssertTrue(configuration.allowedCountries.isEmpty)
    }

    func testBillingDetailsCollectionConfiguration_allowedCountries_custom() {
        let allowedCountries: Set<String> = ["US", "CA", "GB"]
        let configuration = PaymentSheet.BillingDetailsCollectionConfiguration(allowedCountries: allowedCountries)
        XCTAssertEqual(configuration.allowedCountries, allowedCountries)
    }

    func testBillingDetailsCollectionConfiguration_allowedCountries_initialization() {
        let configuration = PaymentSheet.BillingDetailsCollectionConfiguration(
            name: .always,
            phone: .never,
            email: .automatic,
            address: .full,
            attachDefaultsToPaymentMethod: true,
            allowedCountries: ["US", "CA"]
        )

        XCTAssertEqual(configuration.name, .always)
        XCTAssertEqual(configuration.phone, .never)
        XCTAssertEqual(configuration.email, .automatic)
        XCTAssertEqual(configuration.address, .full)
        XCTAssertTrue(configuration.attachDefaultsToPaymentMethod)
        XCTAssertEqual(configuration.allowedCountries, ["US", "CA"])
    }

    func testBillingDetailsCollectionConfiguration_allowedCountries_singleCountry() {
        let configuration = PaymentSheet.BillingDetailsCollectionConfiguration(
            allowedCountries: ["US"]
        )

        XCTAssertEqual(configuration.allowedCountries, ["US"])
        XCTAssertEqual(configuration.allowedCountries.count, 1)
        XCTAssertTrue(configuration.allowedCountries.contains("US"))
    }

    func testBillingDetailsCollectionConfiguration_allowedCountries_duplicatesRemoved() {
        // Set should automatically remove duplicates
        let configuration = PaymentSheet.BillingDetailsCollectionConfiguration(
            allowedCountries: ["US", "US", "CA", "CA", "GB"]
        )

        XCTAssertEqual(configuration.allowedCountries.count, 3)
        XCTAssertTrue(configuration.allowedCountries.contains("US"))
        XCTAssertTrue(configuration.allowedCountries.contains("CA"))
        XCTAssertTrue(configuration.allowedCountries.contains("GB"))
    }

    func testBillingDetailsCollectionConfiguration_allowedCountries_equatable() {
        let config1 = PaymentSheet.BillingDetailsCollectionConfiguration(
            name: .always,
            allowedCountries: ["US", "CA"]
        )
        let config2 = PaymentSheet.BillingDetailsCollectionConfiguration(
            name: .always,
            allowedCountries: ["CA", "US"]  // Different order, but same set
        )
        let config3 = PaymentSheet.BillingDetailsCollectionConfiguration(
            name: .always,
            allowedCountries: ["US", "GB"]  // Different countries
        )

        XCTAssertEqual(config1, config2)  // Order shouldn't matter for sets
        XCTAssertNotEqual(config1, config3)  // Different countries should not be equal
    }

    func testBillingDetailsCollectionConfiguration_allowedCountries_mutability() {
        var configuration = PaymentSheet.BillingDetailsCollectionConfiguration()
        XCTAssertTrue(configuration.allowedCountries.isEmpty)

        // Test that we can modify the set after initialization
        configuration.allowedCountries = ["US", "CA", "GB"]
        XCTAssertEqual(configuration.allowedCountries, ["US", "CA", "GB"])

        // Test that we can clear it
        configuration.allowedCountries = []
        XCTAssertTrue(configuration.allowedCountries.isEmpty)
    }
}

extension STPElementsSession {
    static func elementsSessionWithCustomerSessionForPaymentSheet(apiKey: String) -> STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["123"],
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
                                          "apple_pay_preference": "enabled",
                                          "customer": ["payment_methods": [["id": "pm_1234"], ["id": "pm_4567"], ],
                                                       "customer_session": ["id": "cuss_123",
                                                                            "livemode": false,
                                                                            "api_key": apiKey,
                                                                            "api_key_expiry": 123456678,
                                                                            "customer": "cus_456",
                                                                            "components": [
                                                                                "mobile_payment_element": [
                                                                                    "enabled": true,
                                                                                    "features": [
                                                                                        "payment_method_save": "enabled",
                                                                                        "payment_method_remove": "enabled",
                                                                                    ],
                                                                                ],
                                                                                "customer_sheet": [
                                                                                    "enabled": false,
                                                                                ],
                                                                            ],
                                                                           ],
                                                      ],
        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }
}
