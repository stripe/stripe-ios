//
//  STPClientAttributionMetadataTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
class STPClientAttributionMetadataTests: XCTestCase {
    func testCheckoutMetadataInBothEncoders() throws {
        AnalyticsHelper.shared.generateSessionID()
        var configuration = CheckoutController.Configuration(clientSecret: "cs_test_secret_abc", returnURL: "stripe://return")
        configuration.paymentElement = .init()
        configuration.expressCheckoutElement = .init { _ in }
        configuration.shippingAddressElement = .init()
        configuration.currencySelectorElement = .init()
        let response = CheckoutTestHelpers.makeSession([
            "elements_options": ["__checkout_config_id": "config_test"],
            "elements_session": CheckoutTestHelpers.minimalElementsSessionJSON.merging(["config_id": "es_config_test"]) { _, new in new },
        ])

        for confirmingElement: CheckoutController.ConfirmingElement in [.paymentElement, .expressCheckoutElement] {
            // Exercise both a full Checkout and an ECE-only integration.
            if confirmingElement == .expressCheckoutElement {
                configuration.paymentElement = nil
                configuration.shippingAddressElement = nil
                configuration.currencySelectorElement = nil
            }
            let session = CheckoutController.Session(apiResponse: response, localState: .empty, configuration: configuration)
            let attribution = CheckoutAttributionContext(confirmingElement: confirmingElement, configuredElements: configuration.configuredElements)
            let metadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
                intent: .checkout(session),
                elementsSession: session.elementsSession,
                checkoutAttribution: attribution
            )
            let expected: [String: Any] = [
                "client_session_id": try XCTUnwrap(AnalyticsHelper.shared.sessionID),
                "elements_session_config_id": "es_config_test",
                "checkout_session_id": "cs_test",
                "checkout_config_id": "config_test",
                "merchant_integration_source": "checkout",
                "merchant_integration_subtype": confirmingElement == .paymentElement ? "payment-element" : "express-checkout-element",
                "merchant_integration_version": "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion)",
                "merchant_integration_additional_elements": confirmingElement == .paymentElement
                    ? ["payment", "expressCheckout", "address", "currencySelector"] : ["expressCheckout"],
                "payment_method_selection_flow": "automatic",
            ]
            XCTAssertEqual(try metadata.encodeJSONDictionary() as NSDictionary, expected as NSDictionary)
            XCTAssertEqual(STPFormEncoder.dictionary(forObject: metadata)["client_attribution_metadata"] as? NSDictionary, expected as NSDictionary)
        }
    }

    func testDefaultMetadataPreservesMobileElementsInBothEncoders() throws {
        AnalyticsHelper.shared.generateSessionID()
        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 100, currency: "usd")) { _, _ in
            return ""
        })
        let metadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: intent,
            elementsSession: .emptyElementsSession
        )
        let expected: [String: Any] = [
            "client_session_id": try XCTUnwrap(AnalyticsHelper.shared.sessionID),
            "elements_session_config_id": "123",
            "merchant_integration_source": "elements",
            "merchant_integration_subtype": "mobile",
            "merchant_integration_version": "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion)",
            "payment_intent_creation_flow": "deferred",
            "payment_method_selection_flow": "automatic",
        ]
        XCTAssertEqual(try metadata.encodeJSONDictionary() as NSDictionary, expected as NSDictionary)
        XCTAssertEqual(STPFormEncoder.dictionary(forObject: metadata)["client_attribution_metadata"] as? NSDictionary, expected as NSDictionary)
    }
}
