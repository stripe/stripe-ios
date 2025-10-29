//
//  STPAPIClient+PaymentSheetTest.swift
//  StripeiOS Tests
//
//  Created by Jaime Park on 6/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP)@_spi(CustomPaymentMethodsBeta)@_spi(SharedPaymentToken) import StripePaymentSheet
@testable@_spi(STP) import StripePayments

class STPAPIClient_PaymentSheetTest: XCTestCase {
    func testElementsSessionParameters_DeferredPayment() throws {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 2000,
                                                                           currency: "USD",
                                                                           setupFutureUsage: .onSession,
                                                                           captureMethod: .automaticAsync),
                                                            paymentMethodTypes: ["card", "cashapp"],
                                                            onBehalfOf: "acct_connect",
                                                            paymentMethodConfigurationId: "pmc_234",
                                                            confirmHandler: { _, _, _ in })
        var config = PaymentSheet.Configuration()
        config.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_foo", "external_bar"], externalPaymentMethodConfirmHandler: { _, _, _ in })

        let cpm = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(id: "cpmt_123")
        let cpm2 = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(id: "cpmt_789")
        config.customPaymentMethodConfiguration = .init(customPaymentMethods: [cpm, cpm2], customPaymentMethodConfirmHandler: { _, _ in
            return .completed
        })

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()

        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .deferredIntent(intentConfig),
            epmConfiguration: config.externalPaymentMethodConfiguration,
            cpmConfiguration: config.customPaymentMethodConfiguration,
            clientDefaultPaymentMethod: "pm_12345",
            customerAccessProvider: .customerSession("cs_12345"),
            linkDisallowFundingSourceCreation: []
        )
        XCTAssertNotNil(parameters["mobile_session_id"])
        XCTAssertEqual(parameters["key"] as? String, "pk_test")
        XCTAssertEqual(parameters["locale"] as? String, Locale.current.toLanguageTag())
        XCTAssertEqual(parameters["external_payment_methods"] as? [String], ["external_foo", "external_bar"])
        XCTAssertEqual(parameters["custom_payment_methods"] as? [String], ["cpmt_123", "cpmt_789"])
        XCTAssertEqual(parameters["customer_session_client_secret"] as? String, "cs_12345")
        XCTAssertEqual(parameters["client_default_payment_method"] as? String, "pm_12345")

        let deferredIntent = try XCTUnwrap(parameters["deferred_intent"] as?  [String: Any])
        XCTAssertEqual(deferredIntent["payment_method_types"] as? [String], ["card", "cashapp"])
        XCTAssertEqual(deferredIntent["on_behalf_of"] as? String, "acct_connect")
        XCTAssertEqual(deferredIntent["mode"] as? String, "payment")
        XCTAssertEqual(deferredIntent["amount"] as? Int, 2000)
        XCTAssertEqual(deferredIntent["currency"] as? String, "USD")
        XCTAssertEqual(deferredIntent["setup_future_usage"] as? String, "on_session")
        XCTAssertEqual(deferredIntent["capture_method"] as? String, "automatic_async")
        XCTAssertEqual((deferredIntent["payment_method_configuration"] as? [String: Any])?["id"] as? String, "pmc_234")
    }

    func testElementsSessionParameters_DeferredSetup() throws {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD",
                                                                           setupFutureUsage: .offSession),
                                                            paymentMethodTypes: ["card", "cashapp"],
                                                            onBehalfOf: "acct_connect",
                                                            confirmHandler: { _, _, _ in })
        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()

        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .deferredIntent(intentConfig),
            epmConfiguration: nil,
            cpmConfiguration: nil,
            clientDefaultPaymentMethod: nil,
            customerAccessProvider: .legacyCustomerEphemeralKey("ek_12345"),
            linkDisallowFundingSourceCreation: []
        )
        XCTAssertNotNil(parameters["mobile_session_id"])
        XCTAssertEqual(parameters["key"] as? String, "pk_test")
        XCTAssertEqual(parameters["locale"] as? String, Locale.current.toLanguageTag())
        XCTAssertEqual(parameters["external_payment_methods"] as? [String], [])
        XCTAssertNil(parameters["payment_method_configurations"])
        XCTAssertNil(parameters["customer_session_client_secret"])
        XCTAssertNil(parameters["client_default_payment_method"])

        let deferredIntent = try XCTUnwrap(parameters["deferred_intent"] as?  [String: Any])
        XCTAssertEqual(deferredIntent["payment_method_types"] as? [String], ["card", "cashapp"])
        XCTAssertEqual(deferredIntent["on_behalf_of"] as? String, "acct_connect")
        XCTAssertEqual(deferredIntent["mode"] as? String, "setup")
        XCTAssertEqual(deferredIntent["currency"] as? String, "USD")
        XCTAssertEqual(deferredIntent["setup_future_usage"] as? String, "off_session")
    }

    func testMakeDeferredElementsSessionsParamsForCustomerSheet() throws {
        let parameters = STPAPIClient(publishableKey: "pk_test").makeDeferredElementsSessionsParamsForCustomerSheet(
            paymentMethodTypes: ["card"],
            onBehalfOf: nil,
            clientDefaultPaymentMethod: "pm_12345",
            customerSessionClientSecret: CustomerSessionClientSecret(customerId: "cus_12345", clientSecret: "cuss_54321"))

        XCTAssertEqual(parameters["type"] as? String, "deferred_intent")
        XCTAssertEqual(parameters["locale"] as? String, Locale.current.toLanguageTag())
        XCTAssertEqual(parameters["customer_session_client_secret"] as? String, "cuss_54321")
        XCTAssertEqual(parameters["client_default_payment_method"] as? String, "pm_12345")

        let deferredIntent = try XCTUnwrap(parameters["deferred_intent"] as?  [String: Any])
        XCTAssertEqual(deferredIntent["mode"] as? String, "setup")
        XCTAssertEqual(deferredIntent["payment_method_types"] as? [String], ["card"])

    }
    func testMakeDeferredElementsSessionsParamsForCustomerSheet_nilable() throws {
        let parameters = STPAPIClient(publishableKey: "pk_test").makeDeferredElementsSessionsParamsForCustomerSheet(
            paymentMethodTypes: nil,
            onBehalfOf: nil,
            clientDefaultPaymentMethod: nil,
            customerSessionClientSecret: nil)

        XCTAssertEqual(parameters["type"] as? String, "deferred_intent")
        XCTAssertEqual(parameters["locale"] as? String, Locale.current.toLanguageTag())
        XCTAssertNil(parameters["customer_session_client_secret"])
        XCTAssertNil(parameters["client_default_payment_method"])

        let deferredIntent = try XCTUnwrap(parameters["deferred_intent"] as?  [String: Any])
        XCTAssertEqual(deferredIntent["mode"] as? String, "setup")
        XCTAssertNil(deferredIntent["payment_method_types"])
    }

    func testMakeDeferredElementsSessionsParamsForCustomerSheet_withOnBehalfOf() throws {
        let parameters = STPAPIClient(publishableKey: "pk_test").makeDeferredElementsSessionsParamsForCustomerSheet(
            paymentMethodTypes: ["card"],
            onBehalfOf: "acct_connect",
            clientDefaultPaymentMethod: "pm_12345",
            customerSessionClientSecret: CustomerSessionClientSecret(customerId: "cus_12345", clientSecret: "cuss_54321"))

        XCTAssertEqual(parameters["type"] as? String, "deferred_intent")
        XCTAssertEqual(parameters["locale"] as? String, Locale.current.toLanguageTag())
        XCTAssertEqual(parameters["customer_session_client_secret"] as? String, "cuss_54321")
        XCTAssertEqual(parameters["client_default_payment_method"] as? String, "pm_12345")

        let deferredIntent = try XCTUnwrap(parameters["deferred_intent"] as?  [String: Any])
        XCTAssertEqual(deferredIntent["mode"] as? String, "setup")
        XCTAssertEqual(deferredIntent["payment_method_types"] as? [String], ["card"])
        XCTAssertEqual(deferredIntent["on_behalf_of"] as? String, "acct_connect")
    }

    func testMakeElementsSessionsParamsForCustomerSheet() throws {
        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParamsForCustomerSheet(
            setupIntentClientSecret: "seti_123456",
            clientDefaultPaymentMethod: "pm_12345",
            customerSessionClientSecret: CustomerSessionClientSecret(customerId: "cus_12345", clientSecret: "cuss_54321"))

        XCTAssertEqual(parameters["type"] as? String, "setup_intent")
        XCTAssertEqual(parameters["client_secret"] as? String, "seti_123456")

        XCTAssertEqual(parameters["locale"] as? String, Locale.current.toLanguageTag())
        XCTAssertEqual(parameters["customer_session_client_secret"] as? String, "cuss_54321")
        XCTAssertEqual(parameters["client_default_payment_method"] as? String, "pm_12345")
    }
    func testMakeElementsSessionsParamsForCustomerSheet_nilable() throws {
        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParamsForCustomerSheet(
            setupIntentClientSecret: "seti_123456",
            clientDefaultPaymentMethod: nil,
            customerSessionClientSecret: nil)

        XCTAssertEqual(parameters["type"] as? String, "setup_intent")
        XCTAssertEqual(parameters["client_secret"] as? String, "seti_123456")

        XCTAssertEqual(parameters["locale"] as? String, Locale.current.toLanguageTag())
        XCTAssertNil(parameters["customer_session_client_secret"])
        XCTAssertNil(parameters["client_default_payment_method"])
    }

    func testElementsSessionParameters_sendsLegacyCustomerEphemeralKey() throws {
        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .paymentIntentClientSecret("pi_123_secret_456"),
            epmConfiguration: nil,
            cpmConfiguration: nil,
            clientDefaultPaymentMethod: nil,
            customerAccessProvider: .legacyCustomerEphemeralKey("ek_123"),
            linkDisallowFundingSourceCreation: []
        )
        XCTAssertEqual(parameters["legacy_customer_ephemeral_key"] as? String, "ek_123")
        XCTAssertNil(parameters["customer_session_client_secret"])
    }

    func testElementsSessionParameters_sendsNoLegacyCustomerEphemeralKey() throws {
        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .paymentIntentClientSecret("pi_123_secret_456"),
            epmConfiguration: nil,
            cpmConfiguration: nil,
            clientDefaultPaymentMethod: nil,
            customerAccessProvider: nil,
            linkDisallowFundingSourceCreation: []
        )
        XCTAssertNil(parameters["legacy_customer_ephemeral_key"])
        XCTAssertNil(parameters["customer_session_client_secret"])
    }

    func testElementsSessionParameters_sendsLinkDisallowFundingSourceCreation() throws {
        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .paymentIntentClientSecret("pi_123_secret_456"),
            epmConfiguration: nil,
            cpmConfiguration: nil,
            clientDefaultPaymentMethod: nil,
            customerAccessProvider: nil,
            linkDisallowFundingSourceCreation: ["usInstantBankPayment"]
        )
        let linkParams = try XCTUnwrap(parameters["link"] as? [String: Any])
        XCTAssertEqual(linkParams["disallow_funding_source_creation"] as? [String], ["usInstantBankPayment"])
    }

    func testElementsSessionParameters_doesntSendLinkDisallowFundingSourceCreationIfEmpty() throws {
        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .paymentIntentClientSecret("pi_123_secret_456"),
            epmConfiguration: nil,
            cpmConfiguration: nil,
            clientDefaultPaymentMethod: nil,
            customerAccessProvider: nil,
            linkDisallowFundingSourceCreation: []
        )
        XCTAssertNil(parameters["link"])
    }

    func testElementsSessionParameters_DeferredPayment_WithSellerDetails() throws {
        let sellerDetails = PaymentSheet.IntentConfiguration.SellerDetails(networkId: "network_123", externalId: "external_456", businessName: "Till's Pills")
        let intentConfig = PaymentSheet.IntentConfiguration(
            sharedPaymentTokenSessionWithMode: .payment(amount: 2000, currency: "USD"),
            sellerDetails: sellerDetails,
            paymentMethodTypes: ["card"],
            preparePaymentMethodHandler: { _, _ in }
        )

        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .deferredIntent(intentConfig),
            epmConfiguration: nil,
            cpmConfiguration: nil,
            clientDefaultPaymentMethod: nil,
            customerAccessProvider: nil,
            linkDisallowFundingSourceCreation: []
        )

        let sellerDetailsParams = try XCTUnwrap(parameters["seller_details"] as? [String: Any])

        XCTAssertEqual(sellerDetailsParams["network_id"] as? String, "network_123")
        XCTAssertEqual(sellerDetailsParams["external_id"] as? String, "external_456")
    }

    func testElementsSessionParameters_DeferredPayment_WithoutSellerDetails() throws {
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 2000, currency: "USD"),
            paymentMethodTypes: ["card"],
            confirmHandler: { _, _, _ in }
        )

        let parameters = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .deferredIntent(intentConfig),
            epmConfiguration: nil,
            cpmConfiguration: nil,
            clientDefaultPaymentMethod: nil,
            customerAccessProvider: nil,
            linkDisallowFundingSourceCreation: []
        )

        XCTAssertNil(parameters["seller_details"])
    }
}
