//
//  CheckoutUnitTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
import UIKit
import XCTest

@MainActor
final class CheckoutUnitTests: XCTestCase {

    func testExtractSessionId() {
        XCTAssertEqual(
            CheckoutController.extractSessionId(from: "cs_test_abc123_secret_xyz789"),
            "cs_test_abc123"
        )
        XCTAssertEqual(
            CheckoutController.extractSessionId(from: "cs_live_def456_secret_uvw012"),
            "cs_live_def456"
        )
        // No _secret_ separator returns original
        XCTAssertEqual(
            CheckoutController.extractSessionId(from: "cs_test_nosecret"),
            "cs_test_nosecret"
        )
    }

    func testInitSetsLoadedState() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        XCTAssertFalse(checkout.isUpdating)
        XCTAssertEqual(checkout.session.status, .open)
    }

    func testPaymentElementConfigurationsUseCheckoutReturnURL() async throws {
        // Given a Checkout configuration with a return URL
        let returnURL = "stripe-ios-test://custom-checkout-return"
        let baseConfiguration = CheckoutController.Configuration(
            clientSecret: "cs_test_123_secret_abc",
            returnURL: returnURL
        )

        // When Checkout creates Payment Element's sheet and embedded integrations
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(configuration: baseConfiguration)
        )
        let paymentElement = checkout.getPaymentElement()

        // Then both integrations use the Checkout return URL
        XCTAssertEqual(paymentElement.paymentSheetFlowController.configuration.returnURL, returnURL)
        XCTAssertEqual(paymentElement.embeddedPaymentElement.configuration.returnURL, returnURL)
    }

    func testCurrencySelectorElementConfigurationDefaultsToNil() {
        let configuration = CheckoutController.Configuration(
            clientSecret: "cs_test_123_secret_abc",
            returnURL: "stripe-ios-test://checkout-return"
        )

        XCTAssertNil(configuration.currencySelectorElement)
    }

    func testGetCurrencySelectorElementReturnsNilWhenNotConfigured() async throws {
        // Given an Adaptive Pricing session without Currency Selector Element configuration
        let session = CheckoutTestHelpers.makeAdaptivePricingSession()
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: session)
        )

        // Then Currency Selector Element is disabled
        XCTAssertNil(checkout.getCurrencySelectorElement())
    }

    func testGetCurrencySelectorElementReturnsStableInstanceWhenConfigured() async throws {
        let session = CheckoutTestHelpers.makeAdaptivePricingSession()
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: session)
        )

        let firstElement = try XCTUnwrap(checkout.getCurrencySelectorElement())
        let secondElement = try XCTUnwrap(checkout.getCurrencySelectorElement())
        XCTAssertTrue(firstElement === secondElement)
    }

    func testCurrencySelectorElementLogsInitializationOnce() async throws {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousLogHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousLogHistory }

        let session = CheckoutTestHelpers.makeAdaptivePricingSession()
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: session)
        )

        XCTAssertEqual(currencySelectorInitEvents(in: analyticsClient).count, 1)

        _ = checkout.getCurrencySelectorElement()
        _ = checkout.getCurrencySelectorElement()

        let events = currencySelectorInitEvents(in: analyticsClient)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?["checkout_session_id"] as? String, "cs_test_123")
    }

    func testSessionPaymentOptionUpdatesAndClears() async throws {
        // Given a Checkout with a PaymentElement and valid card payment option
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let paymentElement = checkout.getPaymentElement()
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = NSNumber(value: 2040)
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: paymentElement.embeddedPaymentElement.configuration)

        // When the embedded PaymentElement reports the selected payment option
        paymentElement.embeddedPaymentElement._test_paymentOption = .new(confirmParams: confirmParams)
        paymentElement.embeddedPaymentElementDidUpdatePaymentOption(
            embeddedPaymentElement: paymentElement.embeddedPaymentElement
        )

        // Then the Checkout session mirrors the selected payment option
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "card")
        XCTAssertEqual(checkout.session.paymentOption?.label, "•••• 4242")

        // When the Checkout payment option is cleared
        checkout.clearPaymentOption()

        // Then the Checkout session payment option is cleared
        XCTAssertNil(checkout.session.paymentOption)
    }

    // MARK: - runServerUpdate Tests

    func testRunServerUpdateWrapsClosureError() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let expectedMessage = "Server returned 500"

        do {
            try await checkout.runServerUpdate {
                throw NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: expectedMessage])
            }
            XCTFail("Expected CheckoutError.apiError")
        } catch let error as CheckoutError {
            guard case .apiError(let message) = error else {
                XCTFail("Expected .apiError, got \(error)")
                return
            }
            XCTAssertEqual(message, expectedMessage)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRunServerUpdateWrapsTimeoutError() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())

        do {
            try await checkout.runServerUpdate {
                throw TimeoutError()
            }
            XCTFail("Expected CheckoutError.timedOut")
        } catch let error as CheckoutError {
            guard case .timedOut = error else {
                XCTFail("Expected .timedOut, got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRunServerUpdateWrapsGenericError() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())

        do {
            try await checkout.runServerUpdate {
                throw URLError(.notConnectedToInternet)
            }
            XCTFail("Expected CheckoutError.apiError")
        } catch let error as CheckoutError {
            guard case .apiError(let message) = error else {
                XCTFail("Expected .apiError, got \(error)")
                return
            }
            XCTAssertEqual(message, URLError(.notConnectedToInternet).localizedDescription)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

// MARK: - Address Override Tests

    func testUpdateShippingAddress_noTax_setsLocallyAndEmitsUpdates() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let recorder = CheckoutEmissionRecorder(checkout)

        try await checkout.updateShippingAddress(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )

        let stored = checkout.session.shippingAddress
        XCTAssertEqual(stored?.name, "John Smith")
        XCTAssertEqual(stored?.address.country, "US")
        XCTAssertEqual(recorder.sessions.count, 2)
        XCTAssertEqual(recorder.loading, [true, false])
    }

    func testShippingAddressElementSaveUpdatesCheckoutSession() async throws {
        // Given a ShippingAddressElement connected to its Checkout
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let shippingAddressElement = checkout.getShippingAddressElement()

        // When the element saves a collected address
        try await shippingAddressElement.save(
            addressDetails: .init(
                address: .init(
                    city: "Seattle",
                    country: "US",
                    line1: "123 Main St.",
                    line2: "Apt. 4",
                    postalCode: "98101",
                    state: "WA"
                ),
                name: "Jane Doe"
            )
        )

        // Then the Checkout Session is the source of truth
        XCTAssertEqual(checkout.session.shippingAddress?.name, "Jane Doe")
        XCTAssertEqual(checkout.session.shippingAddress?.address.line1, "123 Main St.")
        XCTAssertEqual(checkout.session.shippingAddress?.address.line2, "Apt. 4")
        XCTAssertEqual(checkout.session.shippingAddress?.address.city, "Seattle")
        XCTAssertEqual(checkout.session.shippingAddress?.address.state, "WA")
        XCTAssertEqual(checkout.session.shippingAddress?.address.postalCode, "98101")
        XCTAssertEqual(checkout.session.shippingAddress?.address.country, "US")
    }

    func testShippingAddressElementDisplaysCheckoutUpdateError() async throws {
        // Given a Checkout Session that updates tax from the shipping address
        var json = CheckoutTestHelpers.openSessionJSON
        json["shipping_address_collection"] = ["allowed_countries": ["US"]]
        json["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.shipping",
        ]
        let session = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)
        var configuration = CheckoutController.Configuration(
            clientSecret: "cs_test_123_secret_abc",
            returnURL: "stripe-ios-test://checkout-return"
        )
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Jane Doe"
        shippingDetails.address = .init(
            country: "US",
            line1: "123 Main St.",
            city: "Seattle",
            state: "WA",
            postalCode: "98101"
        )
        configuration.defaults.shippingDetails = shippingDetails
        configuration = CheckoutTestHelpers.makeConfiguration(
            apiResponse: session,
            configuration: configuration
        )
        let checkout = try await CheckoutController(configuration: configuration)
        let addressViewController = try XCTUnwrap(
            checkout.getShippingAddressElement().addressViewController
        )
        addressViewController.addressSection?.line1?.setText("456 Oak Ave.")

        // ...and the Checkout update API request fails
        stub(condition: { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/payment_pages/cs_test_123"
        }) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "error": [
                        "type": "api_error",
                        "message": "Tax update failed",
                    ],
                ],
                statusCode: 500,
                headers: nil
            )
        }
        let errorDisplayedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { object, _ in
                guard let label = object as? UILabel else { return false }
                return !label.isHidden
            },
            object: addressViewController.errorLabel
        )

        // When the customer saves the shipping address
        addressViewController.didContinue()
        await fulfillment(of: [errorDisplayedExpectation], timeout: 2)

        // Then the SAE form displays the user-facing API error
        XCTAssertFalse(addressViewController.errorLabel.isHidden)
        XCTAssertEqual(addressViewController.errorLabel.text, NSError.stp_unexpectedErrorMessage())
    }

    func testUpdateShippingAddress_disallowedCountry_throws() async throws {
        let session = CheckoutTestHelpers.makeOpenSession(allowedCountries: ["US", "CA"])
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: session))

        do {
            try await checkout.updateShippingAddress(
                address: .init(country: "DE")
            )
            XCTFail("Expected invalidShippingCountry error")
        } catch let error as CheckoutError {
            guard case .invalidShippingCountry("DE") = error else {
                XCTFail("Wrong error case: \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUpdateShippingAddress_allowedCountry_succeeds() async throws {
        let session = CheckoutTestHelpers.makeOpenSession(allowedCountries: ["US", "CA", "GB"])
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: session))

        try await checkout.updateShippingAddress(
            address: .init(country: "CA", line1: "80 Spadina Ave", city: "Toronto", state: "ON", postalCode: "M5V 2J4")
        )

        XCTAssertEqual(checkout.session.shippingAddress?.address.country, "CA")
    }

    func testUpdateShippingAddress_taxUpdateFailurePreservesPreviousAddress() async throws {
        // Given a Checkout Session using shipping address for automatic tax calculation
        var json = CheckoutTestHelpers.openSessionJSON
        json["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.shipping",
        ]
        let session = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: session))

        // ...and a previously stored local shipping address
        let previousAddress = CheckoutController.Session.ShippingAddress(
            name: "Jane Doe",
            address: .init(
                country: "US",
                line1: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105"
            )
        )
        checkout.dangerouslySetSessionDirectly(
            checkout.session.makeCopyOverriding(shippingAddress: .newValue(previousAddress))
        )

        // ...and the server tax update fails
        stub(condition: { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/payment_pages/cs_test_123"
        }) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "error": [
                        "type": "invalid_request_error",
                        "message": "Tax update failed",
                    ],
                ],
                statusCode: 500,
                headers: nil
            )
        }

        // When the customer updates their shipping address
        do {
            try await checkout.updateShippingAddress(
                name: "John Smith",
                address: .init(
                    country: "US",
                    line1: "456 Oak Ave",
                    city: "Los Angeles",
                    state: "CA",
                    postalCode: "90001"
                )
            )
            XCTFail("Expected CheckoutError.apiError")
        } catch let error as CheckoutError {
            guard case .apiError = error else {
                XCTFail("Expected .apiError, got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Then the previous local shipping address is preserved
        XCTAssertEqual(checkout.session.shippingAddress, previousAddress)
    }

    // MARK: - Address Collection Decoding Tests

    func testBillingAddressCollection_whenRequired() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["billing_address_collection"] = "required"
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()
        XCTAssertEqual(session.billingAddressCollection, .required)
    }

    func testBillingAddressCollection_whenAutoOrNil() {
        // "auto" should decode as automatic
        var jsonAuto = CheckoutTestHelpers.openSessionJSON
        jsonAuto["billing_address_collection"] = "auto"
        let sessionAuto = try! PaymentPagesAPIResponse.decode(fromAPIResponse: jsonAuto).makePublicSession()
        XCTAssertEqual(sessionAuto.billingAddressCollection, .automatic)

        // absent field should default to automatic
        let jsonNil = CheckoutTestHelpers.openSessionJSON
        let sessionNil = try! PaymentPagesAPIResponse.decode(fromAPIResponse: jsonNil).makePublicSession()
        XCTAssertEqual(sessionNil.billingAddressCollection, .automatic)
    }

    func testAllowedShippingCountries_whenPresent() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["shipping_address_collection"] = ["allowed_countries": ["US", "CA", "IE", "GB"]]
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()
        XCTAssertEqual(session.allowedShippingCountries, ["US", "CA", "IE", "GB"])
    }

    func testAllowedShippingCountries_whenNil() {
        let json = CheckoutTestHelpers.openSessionJSON
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()
        XCTAssertNil(session.allowedShippingCountries)
    }

    // MARK: - Tax Amount Tests

    func testTotalTaxExclusive_singleAmount() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["recurring_details"] = [
            "total_discount_amounts": [],
            "total_tax_amounts": [
                [
                    "amount": 1185,
                    "inclusive": false,
                    "taxable_amount": 12000,
                    "tax_rate": [
                        "display_name": "Sales Tax",
                        "percentage": 9.875,
                        "jurisdiction": "UT",
                    ],
                ],
            ],
        ]
        setOneTimePriceAmounts(
            in: &json,
            subtotal: 12000,
            taxExclusive: 1185,
            total: 13185
        )
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()
        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 1185)
        XCTAssertEqual(session.taxAmounts?.count, 1)
    }

    func testTotalTaxExclusive_multipleAmounts() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["recurring_details"] = [
            "total_discount_amounts": [],
            "total_tax_amounts": [
                [
                    "amount": 500,
                    "inclusive": false,
                    "taxable_amount": 10000,
                    "tax_rate": [
                        "display_name": "State Tax",
                        "percentage": 5.0,
                        "jurisdiction": "CA",
                    ],
                ],
                [
                    "amount": 200,
                    "inclusive": false,
                    "taxable_amount": 10000,
                    "tax_rate": [
                        "display_name": "County Tax",
                        "percentage": 2.0,
                        "jurisdiction": "LA County",
                    ],
                ],
            ],
        ]
        setOneTimePriceAmounts(
            in: &json,
            subtotal: 10000,
            taxExclusive: 700,
            total: 10700
        )
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()
        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 700)
        XCTAssertEqual(session.taxAmounts?.count, 2)
    }

    func testTotalTaxAmounts_absent_isNil() {
        // Given a response without total_tax_amounts
        let json = CheckoutTestHelpers.openSessionJSON

        // When decoding the public Session
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()

        // Then taxAmounts is nil
        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 0)
        XCTAssertNil(session.taxAmounts)
    }

    func testTotalTaxAmounts_presentButEmpty_isEmpty() {
        // Given a response with an explicitly empty total_tax_amounts array
        var json = CheckoutTestHelpers.openSessionJSON
        json["recurring_details"] = [
            "total_discount_amounts": [],
            "total_tax_amounts": [],
        ]

        // When decoding the public Session
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()

        // Then taxAmounts remains an empty, non-nil array
        XCTAssertNotNil(session.taxAmounts)
        XCTAssertTrue(session.taxAmounts?.isEmpty == true)
    }

    func testAutomaticTaxComplete_zeroTaxableAmount_preservesComputedZeroTax() throws {
        // Given an automatic-tax response observed for an IE shipping address
        let zeroTaxAmount: [String: Any] = [
            "amount": 0,
            "inclusive": false,
            "taxable_amount": 0,
            "tax_rate": [
                "object": "tax_rate",
                "active": true,
                "display_name": "Sales Tax",
                "inclusive": false,
                "percentage": 8.625,
                "rate_type": "percentage",
            ],
        ]
        var json = CheckoutTestHelpers.openSessionJSON
        json["tax_context"] = [
            "automatic_tax_address_source": "session.shipping",
            "automatic_tax_enabled": true,
        ]
        json["tax_meta"] = [
            "computation_type": "automatic",
            "status": "complete",
        ]
        json["recurring_details"] = [
            "subtotal": 12000,
            "total": 12000,
            "total_discount_amounts": [],
            "total_summary": [
                "due": 12000,
                "subtotal": 12000,
                "total": 12000,
                "total_discount_amount_aggregate": 0,
                "total_discount_amounts": [],
                "total_proration_amount_aggregate": 0,
                "total_tax_amounts": [zeroTaxAmount],
            ],
            "total_tax_amounts": [zeroTaxAmount],
        ]
        setOneTimePriceAmounts(
            in: &json,
            subtotal: 12000,
            taxExclusive: 0,
            total: 12000
        )

        // When decoding the response into the public Session
        let session = try PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()
        let taxAmount = try XCTUnwrap(session.taxAmounts?.first)

        // Then the completed computation and its present zero-valued tax entry are preserved
        XCTAssertEqual(session.tax?.status, .ready)
        XCTAssertEqual(session.taxAmounts?.count, 1)
        XCTAssertEqual(taxAmount.minorUnitsAmount, 0)
        XCTAssertFalse(taxAmount.inclusive)
        XCTAssertEqual(taxAmount.displayName, "Sales Tax")
        XCTAssertEqual(taxAmount.percentage, 8.625)
        XCTAssertEqual(session.totals.subtotal.minorUnitsAmount, 12000)
        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 0)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 12000)
    }

    func testSessionDebugDescription_isReadableAndMasksCustomerInformation() {
        // Given a session containing customer information
        var sessionJSON = CheckoutTestHelpers.openSessionJSON
        sessionJSON["customer_email"] = "jenny@example.com"
        let localCurrencyOption: [String: Any] = [
            "currency": "gbp",
            "amount": 800,
            "presentment_exchange_rate": "0.8",
            "conversion_markup_bps": 400,
        ]
        sessionJSON["adaptive_pricing_info"] = [
            "integration_currency": "usd",
            "integration_amount": 1000,
            "active_presentment_currency": "gbp",
            "local_currency_options": [localCurrencyOption],
        ]
        let discountAmount: [String: Any] = [
            "amount": 500,
            "coupon": ["code": "coupon_test", "name": "Summer sale"],
            "promotion_code": ["code": "SUMMER"],
        ]
        sessionJSON["recurring_details"] = [
            "total_discount_amounts": [discountAmount],
            "total_tax_amounts": [],
        ]
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: sessionJSON)
            .makePublicSession()
            .makeCopyOverriding(
                shippingAddress: .newValue(
                    .init(
                        name: "Jenny Rosen",
                        address: .init(
                            country: "US",
                            line1: "510 Townsend Street",
                            city: "San Francisco",
                            state: "CA",
                            postalCode: "94103"
                        )
                    )
                ),
                paymentOption: .newValue(
                    .init(
                        image: UIImage(),
                        label: "Visa ending in 4242",
                        billingDetails: .init(
                            address: .init(
                                city: "San Francisco",
                                country: "US",
                                line1: "510 Townsend Street",
                                postalCode: "94103",
                                state: "CA"
                            ),
                            email: "jenny@example.com",
                            name: "Jenny Rosen",
                            phone: "+14155550123"
                        ),
                        paymentMethodType: "card",
                        mandateText: NSAttributedString(string: "Mandate text")
                    )
                )
            )

        // When generating its debug description
        let description = session.debugDescription

        // Then it preserves useful context and masks customer information
        XCTAssertEqual(
            description,
            """
            CheckoutController.Session {
              id: "cs_test_123"
              status: .open
              livemode: false
              businessName: nil
              currency: "usd"
              presentmentDetails: {
                presentmentCurrency: "gbp"
              }
              discountAmounts: [
                {
                  amount: "$5.00"
                  minorUnitsAmount: 500.0
                  displayName: "Summer sale"
                  promotionCode: <redacted>
                  percentOff: nil
                }
              ]
              email: "j***y@example.com"
              minorUnitsAmountDivisor: 100
              paymentOption: {
                paymentMethodType: "card"
                label: "Visa ending in 4242"
                billingDetails: {
                  country: "US"
                }
                mandateText: <redacted>
              }
              shippingAddress: {
                country: "US"
              }
              orderSummaryItems: [
                [0] oneTimePrice {
                  key: "checkout_item_test"
                  items: [
                    [0] {
                      key: "checkout_item_inner_test"
                      quantity: 1
                      unitAmount: "$10.00"
                      unitAmountDecimal: "$10.00"
                      adjustableQuantity: nil
                    }
                  ]
                  subtotal: "$10.00"
                  discount: "$0.00"
                  taxExclusive: "$0.00"
                  taxInclusive: "$0.00"
                  taxAmountCount: nil
                  total: "$10.00"
                }
              ]
              taxStatus: nil
              taxAmountCount: 0
              totals: {
                subtotal: "$10.00"
                taxExclusive: "$0.00"
                taxInclusive: "$0.00"
                discount: "$0.00"
                total: "$10.00"
              }
            }
            """
        )
    }

    func testSessionDebugDescription_preservesAbsentAndEmptyTaxAmounts() {
        // Given sessions with absent and present-but-empty tax amounts
        let absent = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        var emptyJSON = CheckoutTestHelpers.openSessionJSON
        emptyJSON["recurring_details"] = [
            "total_discount_amounts": [],
            "total_tax_amounts": [],
        ]
        let empty = try! PaymentPagesAPIResponse.decode(fromAPIResponse: emptyJSON).makePublicSession()

        // Then their debug descriptions preserve the distinction
        XCTAssertTrue(absent.debugDescription.contains("taxAmountCount: nil"))
        XCTAssertTrue(empty.debugDescription.contains("taxAmountCount: 0"))
    }

    // MARK: - Requires Shipping Address Tests

    func testRequiresShippingAddress_whenCountriesPresent() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["shipping_address_collection"] = ["allowed_countries": ["US", "CA"]]
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()
        XCTAssertTrue(session.requiresShippingAddress)
    }

    func testRequiresShippingAddress_whenNil() {
        let json = CheckoutTestHelpers.openSessionJSON
        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()
        XCTAssertFalse(session.requiresShippingAddress)
    }

    // MARK: - Full Session Decoding with Tax Amounts

    func testFullSessionDecodingWithTaxAmounts() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["billing_address_collection"] = "required"
        json["shipping_address_collection"] = ["allowed_countries": ["US", "CA", "GB"]]
        json["recurring_details"] = [
            "total_discount_amounts": [],
            "total_tax_amounts": [
                [
                    "amount": 1000,
                    "inclusive": false,
                    "taxable_amount": 20000,
                    "tax_rate": [
                        "display_name": "Sales Tax",
                        "percentage": 5.0,
                        "jurisdiction": "NY",
                    ],
                ],
            ],
        ]
        setOneTimePriceAmounts(
            in: &json,
            subtotal: 20000,
            taxExclusive: 1000,
            total: 21000
        )

        let session = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()

        // Verify tax amounts
        XCTAssertEqual(session.taxAmounts?.count, 1)
        XCTAssertEqual(session.taxAmounts?.first?.minorUnitsAmount, 1000)
        XCTAssertEqual(session.taxAmounts?.first?.displayName, "Sales Tax")

        // Verify address collection settings
        XCTAssertEqual(session.billingAddressCollection, .required)
        XCTAssertTrue(session.requiresShippingAddress)
        XCTAssertEqual(session.allowedShippingCountries, ["US", "CA", "GB"])

        // Verify totals
        XCTAssertEqual(session.totals.subtotal.minorUnitsAmount, 20000)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 21000)
        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 1000)
    }

    // MARK: - commitSession Tests

    func testUpdateSessionEmitsSessionUpdates() async throws {
        // Given a Checkout with a session recorder
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let recorder = CheckoutEmissionRecorder(checkout)

        var updatedJSON = CheckoutTestHelpers.openSessionJSON
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let confirmResponse = try PaymentPagesAPIResponse.decode(fromAPIResponse: updatedJSON)

        // When the confirmed session is committed
        try await checkout.commitSession(confirmResponse)

        // Then Checkout updates the session and notifies observers
        XCTAssertEqual(checkout.session.status, .complete(.paid))
        // There are two emissions: one for the committed session, one for PaymentElement re-syncing the payment option.
        XCTAssertEqual(recorder.sessions.count, 2)
    }

    func testUpdateSessionCarriesOverAddressOverrides() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())

        // Set address overrides on the initial session
        let shippingUpdate = CheckoutController.Session.ShippingAddress(
            name: "Jane Doe",
            address: .init(country: "US")
        )
        checkout.dangerouslySetSessionDirectly(
            checkout.session.makeCopyOverriding(shippingAddress: .newValue(shippingUpdate))
        )

        // Simulate a confirm response
        var updatedJSON = CheckoutTestHelpers.openSessionJSON
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let confirmResponse = try PaymentPagesAPIResponse.decode(fromAPIResponse: updatedJSON)

        try await checkout.commitSession(confirmResponse)

        // Address overrides should be carried over to the new session
        XCTAssertEqual(checkout.session.shippingAddress?.name, "Jane Doe")
        XCTAssertEqual(checkout.session.shippingAddress?.address.country, "US")
    }

    func testUpdateSessionCarriesOverAndClearsLocalPaymentOption() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let paymentElement = checkout.getPaymentElement()
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = NSNumber(value: 2040)
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(
            for: paymentElement.embeddedPaymentElement.configuration
        )
        paymentElement.embeddedPaymentElement._test_paymentOption = .new(confirmParams: confirmParams)
        paymentElement.embeddedPaymentElementDidUpdatePaymentOption(
            embeddedPaymentElement: paymentElement.embeddedPaymentElement
        )

        var updatedJSON = CheckoutTestHelpers.openSessionJSON
        updatedJSON["status"] = "complete"
        let confirmResponse = try PaymentPagesAPIResponse.decode(fromAPIResponse: updatedJSON)

        try await checkout.commitSession(confirmResponse)

        XCTAssertEqual(checkout.session.paymentOption?.label, "•••• 4242")
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "card")

        checkout.clearPaymentOption()

        XCTAssertNil(checkout.session.paymentOption)
    }

    func testUpdateSessionCanBeCalledMultipleTimes() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let recorder = CheckoutEmissionRecorder(checkout)

        var firstResponse = CheckoutTestHelpers.openSessionJSON
        firstResponse["status"] = "complete"
        firstResponse["payment_status"] = "paid"
        let firstConfirm = try PaymentPagesAPIResponse.decode(fromAPIResponse: firstResponse)

        try await checkout.commitSession(firstConfirm)
        XCTAssertEqual(checkout.session.status, .complete(.paid))

        var secondResponse = CheckoutTestHelpers.openSessionJSON
        secondResponse["status"] = "open"
        let secondSession = try PaymentPagesAPIResponse.decode(fromAPIResponse: secondResponse)

        try await checkout.commitSession(secondSession)
        XCTAssertEqual(checkout.session.status, .open)
        XCTAssertEqual(recorder.sessions.count, 4)
    }

    // MARK: - State Convenience Tests

    func testSessionAvailableAfterInit() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        XCTAssertEqual(checkout.session.status, .open)
    }

    func testIsLoadingFalseAfterInit() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        XCTAssertFalse(checkout.isUpdating)
    }

    // MARK: - Confirmation Result Tests

    func testMapCompletedConfirmationResultUsesResponsePaymentStatus() async throws {
        // Given a completed Checkout Session response
        var responseJSON = CheckoutTestHelpers.openSessionJSON
        responseJSON["status"] = "complete"
        responseJSON["payment_status"] = "paid"
        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: responseJSON)

        // When the internal result is mapped to the public result
        let result = CheckoutController.mapConfirmationResult(.completed(response))

        // Then success preserves the Checkout Session payment status
        guard case .succeeded(let paymentStatus) = result else {
            return XCTFail("Expected confirmation to succeed")
        }
        XCTAssertEqual(paymentStatus, .paid)
    }

    func testMapCanceledConfirmationResult() async throws {
        // When the internal result is mapped to the public result
        let result = CheckoutController.mapConfirmationResult(.canceled())

        // Then cancellation is preserved
        guard case .canceled = result else {
            return XCTFail("Expected confirmation to be canceled")
        }
    }

    // MARK: - updatePaymentMethod Parameter Encoding Tests

    func testUpdatePaymentMethodParameters_expiryOnly() {
        let params = STPAPIClient.updatePaymentMethodParameters(
            paymentMethodId: "pm_123",
            billingDetails: nil,
            expiryDetails: CheckoutController.PaymentMethodExpiryDetails(expMonth: 12, expYear: 2028)
        )

        XCTAssertEqual(params["payment_method_to_update[payment_method_id]"] as? String, "pm_123")
        XCTAssertEqual(params["payment_method_to_update[expiry_details][exp_month]"] as? Int, 12)
        XCTAssertEqual(params["payment_method_to_update[expiry_details][exp_year]"] as? Int, 2028)
        XCTAssertNil(params["payment_method_to_update[billing_details][name]"])
        XCTAssertEqual(params.count, 3)
    }

    func testUpdatePaymentMethodParameters_billingDetailsOnly() {
        let billing = CheckoutController.PaymentMethodBillingDetails(
            name: "Jane Doe",
            email: "jane@example.com",
            phone: "+15551234567",
            address: CheckoutController.PaymentMethodBillingAddress(
                line1: "123 Main St",
                line2: "Apt 4",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "US"
            )
        )
        let params = STPAPIClient.updatePaymentMethodParameters(
            paymentMethodId: "pm_456",
            billingDetails: billing,
            expiryDetails: nil
        )

        XCTAssertEqual(params["payment_method_to_update[payment_method_id]"] as? String, "pm_456")
        XCTAssertEqual(params["payment_method_to_update[billing_details][name]"] as? String, "Jane Doe")
        XCTAssertEqual(params["payment_method_to_update[billing_details][email]"] as? String, "jane@example.com")
        XCTAssertEqual(params["payment_method_to_update[billing_details][phone]"] as? String, "+15551234567")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][line1]"] as? String, "123 Main St")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][line2]"] as? String, "Apt 4")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][city]"] as? String, "San Francisco")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][state]"] as? String, "CA")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][postal_code]"] as? String, "94105")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][country]"] as? String, "US")
        XCTAssertNil(params["payment_method_to_update[expiry_details][exp_month]"])
        XCTAssertEqual(params.count, 10)
    }

    func testUpdatePaymentMethodParameters_billingAndExpiry() {
        let billing = CheckoutController.PaymentMethodBillingDetails(
            name: "John Smith",
            address: nil
        )
        let expiry = CheckoutController.PaymentMethodExpiryDetails(expMonth: 3, expYear: 2026)
        let params = STPAPIClient.updatePaymentMethodParameters(
            paymentMethodId: "pm_789",
            billingDetails: billing,
            expiryDetails: expiry
        )

        XCTAssertEqual(params["payment_method_to_update[payment_method_id]"] as? String, "pm_789")
        XCTAssertEqual(params["payment_method_to_update[billing_details][name]"] as? String, "John Smith")
        XCTAssertEqual(params["payment_method_to_update[expiry_details][exp_month]"] as? Int, 3)
        XCTAssertEqual(params["payment_method_to_update[expiry_details][exp_year]"] as? Int, 2026)
        XCTAssertNil(params["payment_method_to_update[billing_details][email]"])
        XCTAssertNil(params["payment_method_to_update[billing_details][address][line1]"])
        XCTAssertEqual(params.count, 4)
    }

    func testUpdatePaymentMethodParameters_partialBillingAddress() {
        let billing = CheckoutController.PaymentMethodBillingDetails(
            address: CheckoutController.PaymentMethodBillingAddress(
                postalCode: "94105",
                country: "US"
            )
        )
        let params = STPAPIClient.updatePaymentMethodParameters(
            paymentMethodId: "pm_abc",
            billingDetails: billing,
            expiryDetails: nil
        )

        XCTAssertEqual(params["payment_method_to_update[payment_method_id]"] as? String, "pm_abc")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][postal_code]"] as? String, "94105")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][country]"] as? String, "US")
        XCTAssertNil(params["payment_method_to_update[billing_details][name]"])
        XCTAssertNil(params["payment_method_to_update[billing_details][address][line1]"])
        XCTAssertNil(params["payment_method_to_update[billing_details][address][city]"])
        XCTAssertEqual(params.count, 3)
    }

    private func setOneTimePriceAmounts(
        in json: inout [AnyHashable: Any],
        subtotal: Int,
        taxExclusive: Int,
        taxInclusive: Int = 0,
        total: Int
    ) {
        var checkoutItems = json["checkout_items"] as! [[String: Any]]
        var checkoutItem = checkoutItems[0]
        var oneTimePrice = checkoutItem["one_time_price"] as! [String: Any]
        var items = oneTimePrice["items"] as! [[String: Any]]
        var item = items[0]
        item["subtotal"] = subtotal
        item["tax_exclusive"] = taxExclusive
        item["tax_inclusive"] = taxInclusive
        item["total"] = total
        items[0] = item
        oneTimePrice["items"] = items
        oneTimePrice["subtotal"] = subtotal
        oneTimePrice["total"] = total
        checkoutItem["one_time_price"] = oneTimePrice
        checkoutItems[0] = checkoutItem
        json["checkout_items"] = checkoutItems
    }

}

private func currencySelectorInitEvents(in analyticsClient: STPAnalyticsClient) -> [[String: Any]] {
    analyticsClient._testLogHistory.filter {
        $0["event"] as? String == STPAnalyticEvent.adaptivePricingCurrencySelectorInit.rawValue
    }
}
