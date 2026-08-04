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
@testable@_spi(STP)@_spi(DashboardOnly)@_spi(SharedPaymentToken) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPAPIClient_PaymentSheetTest: XCTestCase {
    func testMobileSessionUsesDahliaAPIVersion() {
        let apiClient = STPAPIClient(publishableKey: "pk_test")

        XCTAssertEqual(
            apiClient.mobileSessionAPIVersionHeaders["Stripe-Version"],
            "2026-07-29.dahlia"
        )
    }

    func testMobileSessionResponseValidatorAcceptsDiagnosticRevisionDrift() throws {
        let serverRevision = "0000000000000000"
        let response = makeMobileSessionHTTPResponse()
        let responseJSON = makeMobileSessionResponseJSON(revision: serverRevision)

        try STPAPIClient.validateMobileSessionContractResponse(responseJSON, response)
    }

    func testMobileSessionResponseValidatorRejectsUnsupportedMajor() {
        assertMobileSessionContractError(
            expectedCode: "unsupported_contract_major",
            response: makeMobileSessionHTTPResponse(),
            responseJSON: makeMobileSessionResponseJSON(major: MobileSessionContractV1.contractMajor + 1)
        )
    }

    func testMobileSessionResponseValidatorRejectsMissingPayload() {
        assertMobileSessionContractError(
            expectedCode: "missing_payload",
            response: makeMobileSessionHTTPResponse(),
            responseJSON: [:]
        )
    }

    func testAPIRequestPropagatesMobileSessionResponseValidationError() throws {
        let expectation = expectation(description: "response validator")
        let response = makeMobileSessionHTTPResponse()
        let responseJSON = makeMobileSessionResponseJSON(major: MobileSessionContractV1.contractMajor + 1)
        let body = try JSONSerialization.data(withJSONObject: responseJSON)

        APIRequest<STPElementsSession>.parseResponse(
            response,
            method: "GET",
            body: body,
            error: nil,
            responseValidator: STPAPIClient.validateMobileSessionContractResponse
        ) { object, _, error in
            XCTAssertNil(object)
            XCTAssertEqual((error as? MobileSessionContractError)?.analyticsErrorCode, "unsupported_contract_major")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testMobileSessionRequestFailureDoesNotEnterLegacyFallback() {
        let serverError = NSError(
            domain: STPError.stripeDomain,
            code: 0,
            userInfo: [STPError.httpStatusCodeKey: 500]
        )

        XCTAssertFalse(
            PaymentSheetLoader.shouldFallback(for: MobileSessionContractError.requestFailed(serverError))
        )
    }

    private func assertMobileSessionContractError(
        expectedCode: String,
        response: HTTPURLResponse,
        responseJSON: [AnyHashable: Any]? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let responseJSON = responseJSON ?? makeMobileSessionResponseJSON()
        XCTAssertThrowsError(
            try STPAPIClient.validateMobileSessionContractResponse(responseJSON, response),
            file: file,
            line: line
        ) { error in
            XCTAssertEqual(
                (error as? MobileSessionContractError)?.analyticsErrorCode,
                expectedCode,
                file: file,
                line: line
            )
        }
    }

    private func makeMobileSessionHTTPResponse() -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://api.stripe.com/v1/elements/sessions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [:]
        )!
    }

    private func makeMobileSessionResponseJSON(
        major: Int = MobileSessionContractV1.contractMajor,
        revision: String = MobileSessionContractV1.contractRevision
    ) -> [AnyHashable: Any] {
        [
            "session_id": "elements_session_123",
            "payment_method_preference": [
                "object": "payment_method_preference",
                "ordered_payment_method_types": [],
            ],
            "mobile_payment_element": [
                "contract": [
                    "major": major,
                    "revision": revision,
                ],
                "payment_method_availability": ["entries": []],
            ],
        ]
    }

    func testPaymentSheetConfigurationMapsPrivacyMinimizedCapabilities() {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.merchantDisplayName = "Merchant"
        configuration.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123_secret")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_custom")
        configuration.defaultBillingDetails.name = "Jenny"
        configuration.defaultBillingDetails.email = "jenny@example.com"
        configuration.defaultBillingDetails.phone = "5551234567"
        configuration.defaultBillingDetails.address = .init(
            city: "London",
            country: "GB",
            line1: "1 Main St",
            line2: "Flat 2",
            postalCode: "SW1A 1AA",
            state: "London"
        )
        configuration.primaryButtonLabel = "Pay"
        configuration.externalPaymentMethodConfiguration = .init(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _ in .canceled }
        )
        var customPaymentMethod = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(
            id: "cpmt_123",
            subtitle: "Pay another way"
        )
        customPaymentMethod.disableBillingDetailCollection = false
        configuration.customPaymentMethodConfiguration = .init(
            customPaymentMethods: [customPaymentMethod],
            customPaymentMethodConfirmHandler: { _, _ in .completed }
        )
        configuration.paymentMethodOrder = ["card", "link"]
        configuration.paymentMethodLayout = .vertical
        configuration.cardBrandAcceptance = .allowed(brands: [.visa])
        configuration.termsDisplay = [.card: .never]
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        configuration.removeSavedPaymentMethodMessage = "Remove this payment method?"
        configuration.opensCardScannerAutomatically = true
        configuration.disableWalletPaymentMethodFiltering = true
        configuration.linkPaymentMethodsOnly = true
        configuration.willUseWalletButtonsView = true
        configuration.walletButtonsVisibility.paymentElement = [.link: .never]
        configuration.walletButtonsVisibility.walletButtonsView = [.applePay: .never]
        configuration.userOverrideCountry = "CA"

        let mapped = configuration.paymentSheetConfig

        XCTAssertEqual(mapped.applePay?.merchantCountryCode, "US")
        XCTAssertEqual(mapped.link.display, "automatic")
        XCTAssertTrue(mapped.returnUrlProvided)
        XCTAssertTrue(mapped.merchantDisplayNameProvided)
        XCTAssertTrue(mapped.customerConfigured)
        XCTAssertEqual(mapped.customerAccessType, "customer_session")
        XCTAssertTrue(mapped.customApiClient)
        XCTAssertTrue(mapped.defaultBillingDetails.addressLine2)
        XCTAssertEqual(mapped.defaultBillingDetails.addressCountryCode, "GB")
        XCTAssertTrue(mapped.primaryButtonLabelProvided)
        XCTAssertEqual(mapped.externalPaymentMethods, ["external_paypal"])
        XCTAssertTrue(mapped.externalPaymentMethodHandlerProvided)
        XCTAssertEqual(mapped.customPaymentMethodIds, ["cpmt_123"])
        XCTAssertTrue(mapped.customPaymentMethodHandlerProvided)
        XCTAssertTrue(mapped.customPaymentMethods.first?.subtitleProvided == true)
        XCTAssertFalse(mapped.customPaymentMethods.first?.disableBillingDetailCollection ?? true)
        XCTAssertEqual(mapped.paymentMethodOrder, ["card", "link"])
        XCTAssertEqual(mapped.paymentMethodLayout, "vertical")
        XCTAssertEqual(mapped.cardBrandAcceptance.brands, ["visa"])
        XCTAssertEqual(mapped.termsDisplay, ["card": "never"])
        XCTAssertFalse(mapped.allowsRemovalOfLastSavedPaymentMethod)
        XCTAssertTrue(mapped.removeSavedPaymentMethodMessageProvided)
        XCTAssertTrue(mapped.opensCardScannerAutomatically)
        XCTAssertTrue(mapped.disableWalletPaymentMethodFiltering)
        XCTAssertTrue(mapped.linkPaymentMethodsOnly)
        XCTAssertTrue(mapped.walletButtons.willDisplayExternally)
        XCTAssertEqual(mapped.walletButtons.paymentElement, ["link": "never"])
        XCTAssertEqual(mapped.walletButtons.walletButtonsView, ["apple_pay": "never"])
        XCTAssertEqual(mapped.userOverrideCountry, "CA")
    }

    func testElementsSessionParameters_DeferredPayment() throws {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 2000,
                                                                           currency: "USD",
                                                                           setupFutureUsage: .onSession,
                                                                           captureMethod: .automaticAsync),
                                                            paymentMethodTypes: ["card", "cashapp"],
                                                            onBehalfOf: "acct_connect",
                                                            paymentMethodConfigurationId: "pmc_234",
                                                            confirmHandler: { _, _ in return "" })
        var config = PaymentSheet.Configuration()
        config.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_foo", "external_bar"], externalPaymentMethodConfirmHandler: { _, _ in return .canceled })

        let cpm = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(id: "cpmt_123")
        let cpm2 = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(id: "cpmt_789")
        config.customPaymentMethodConfiguration = .init(customPaymentMethods: [cpm, cpm2], customPaymentMethodConfirmHandler: { _, _ in
            return .completed
        })

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()

        let parameters = try STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
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
                                                            confirmHandler: { _, _ in return "" })
        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()

        let parameters = try STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
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
        let parameters = try STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
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
        let parameters = try STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
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
        let parameters = try STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
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
        let parameters = try STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .paymentIntentClientSecret("pi_123_secret_456"),
            epmConfiguration: nil,
            cpmConfiguration: nil,
            clientDefaultPaymentMethod: nil,
            customerAccessProvider: nil,
            linkDisallowFundingSourceCreation: []
        )
        XCTAssertNil(parameters["link"])
    }

    func testElementsSessionParameters_sendsPaymentSheetConfig() throws {
        let parameters = try STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
            mode: .paymentIntentClientSecret("pi_123_secret_456"),
            epmConfiguration: nil,
            cpmConfiguration: nil,
            clientDefaultPaymentMethod: nil,
            customerAccessProvider: nil,
            linkDisallowFundingSourceCreation: [],
            paymentSheetConfig: PaymentSheetConfigV1(
                merchantCountryCode: "GB",
                allowsDelayedPaymentMethods: true,
                allowsPaymentMethodsRequiringShippingAddress: true,
                applePay: ApplePayConfigV1(merchantCountryCode: "GB", merchantId: "merchant.example"),
                link: LinkConfigV1(display: "never", disabledFundingSources: ["card"]),
                returnUrlProvided: true,
                preferredNetworks: ["visa"],
                billingDetailsCollectionConfiguration: BillingDetailsCollectionConfigV1(
                    name: "always",
                    phone: "never",
                    email: "automatic",
                    address: "full",
                    attachDefaultsToPaymentMethod: true,
                    allowedCountries: ["GB"]
                ),
                externalPaymentMethods: ["external_paypal"],
                customPaymentMethodIds: ["cpmt_123"],
                paymentMethodOrder: ["card", "link"],
                paymentMethodLayout: "vertical",
                cardBrandAcceptance: CardBrandAcceptanceV1(filter: "allowed", brands: ["visa"]),
                allowedCardFundingTypes: ["credit"],
                termsDisplay: ["card": "never"]
            )
        )

        let config = try XCTUnwrap(parameters["payment_sheet_config"] as? [String: Any])
        XCTAssertEqual(config["merchant_country_code"] as? String, "GB")
        XCTAssertEqual(config["allows_delayed_payment_methods"] as? Bool, true)
        XCTAssertEqual(config["allows_payment_methods_requiring_shipping_address"] as? Bool, true)
        XCTAssertEqual((config["apple_pay"] as? [String: Any])?["merchant_id"] as? String, "merchant.example")
        XCTAssertEqual((config["link"] as? [String: Any])?["display"] as? String, "never")
        XCTAssertEqual(config["return_url_provided"] as? Bool, true)
        XCTAssertNil(config["return_url"])
        XCTAssertEqual(config["preferred_networks"] as? [String], ["visa"])
        XCTAssertEqual(config["external_payment_methods"] as? [String], ["external_paypal"])
        XCTAssertEqual(config["custom_payment_method_ids"] as? [String], ["cpmt_123"])
        XCTAssertEqual(config["payment_method_order"] as? [String], ["card", "link"])
        XCTAssertEqual(config["payment_method_layout"] as? String, "vertical")
        XCTAssertEqual(config["allowed_card_funding_types"] as? [String], ["credit"])
        XCTAssertEqual(config["terms_display"] as? [String: String], ["card": "never"])
    }

    func testElementsSessionParameters_DeferredPayment_WithSellerDetails() throws {
        let sellerDetails = PaymentSheet.IntentConfiguration.SellerDetails(networkId: "network_123", externalId: "external_456", businessName: "Till's Pills")
        let intentConfig = PaymentSheet.IntentConfiguration(
            sharedPaymentTokenSessionWithMode: .payment(amount: 2000, currency: "USD"),
            sellerDetails: sellerDetails,
            paymentMethodTypes: ["card"],
            preparePaymentMethodHandler: { _, _ in }
        )

        let parameters = try STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
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
            confirmHandler: { _, _ in return "" }
        )

        let parameters = try STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(
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
