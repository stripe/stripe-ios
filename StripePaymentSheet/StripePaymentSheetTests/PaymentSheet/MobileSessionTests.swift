//
//  MobileSessionTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/4/26.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsTestUtils

@MainActor
class MobileSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        STPAnalyticsClient.sharedClient._testLogHistory = []
    }

    override func tearDown() {
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = false
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
        super.tearDown()
    }

    // MARK: - Config

    func testConfigHeader_fullyPopulated() throws {
        // Given a configuration with every mapped field set
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "foo://bar"
        configuration.defaultBillingDetails.email = " jane@example.com "
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = true
        configuration.link = .init(display: .walletButtonHidden)
        configuration.cardBrandAcceptance = .disallowed(brands: [.amex])
        configuration.paymentMethodOrder = ["card", "external_paypal"]

        // When it's encoded, with a fixed environment since that depends on the test host
        var config = MobileSession.Config(configuration: configuration)
        config.environment = .init(hasFinancialConnectionsSdk: true, deviceSupportsNativeLink: true)
        let header = try MobileSession.encodeHeaderValue(config)

        // Then it matches the golden JSON, which is the spec's fully populated iOS example
        XCTAssertEqual(
            header,
            #"{"environment":{"device_supports_native_link":true,"has_financial_connections_sdk":true},"payment_element_config":{"allows_delayed_payment_methods":true,"billing_details_collection":{"address":"full","attach_defaults_to_payment_method":true,"email":"always","name":"always","phone":"never"},"card_brand_acceptance":{"brands":["amex"],"filter":"disallowed"},"default_billing_details":{"email":true},"has_return_url":true,"link":{"display_mode":"wallet_button_hidden"},"payment_method_order":["card","external_paypal"]},"spec_hash":"2cffd7a0"}"#
        )
        // ...and never contains customer values
        XCTAssertFalse(header.contains("jane"))
        XCTAssertFalse(header.contains("foo"))
    }

    func testConfigHeader_minimal() throws {
        // Given a default configuration
        let configuration = PaymentSheet.Configuration()

        // When it's encoded, with a fixed environment since that depends on the test host
        var config = MobileSession.Config(configuration: configuration)
        config.environment = .init(hasFinancialConnectionsSdk: false, deviceSupportsNativeLink: false)
        let header = try MobileSession.encodeHeaderValue(config)

        // Then it matches the golden JSON, with every field present
        XCTAssertEqual(
            header,
            #"{"environment":{"device_supports_native_link":false,"has_financial_connections_sdk":false},"payment_element_config":{"allows_delayed_payment_methods":false,"billing_details_collection":{"address":"automatic","attach_defaults_to_payment_method":false,"email":"automatic","name":"automatic","phone":"automatic"},"card_brand_acceptance":{"brands":[],"filter":"all"},"default_billing_details":{"email":false},"has_return_url":false,"link":{"display_mode":"automatic"},"payment_method_order":[]},"spec_hash":"2cffd7a0"}"#
        )
    }

    func testConfigHeader_escapesNonASCII() throws {
        // Given a configuration with non-ASCII payment method types, including one outside the Basic Multilingual Plane
        var configuration = PaymentSheet.Configuration()
        configuration.paymentMethodOrder = ["café", "😀"]

        // When it's encoded
        let header = try MobileSession.encodeHeaderValue(MobileSession.Config(configuration: configuration))

        // Then the header is ASCII, with each UTF-16 code unit escaped
        XCTAssertTrue(header.allSatisfy { $0.isASCII })
        XCTAssertTrue(header.contains(#""payment_method_order":["caf\u00e9","\ud83d\ude00"]"#))
        // ...and it still decodes to the original values
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(header.utf8)) as? [String: Any])
        XCTAssertEqual(json[jsonDict: "payment_element_config"]?["payment_method_order"] as? [String], ["café", "😀"])
    }

    func testConfig_blankValuesAreAbsent() {
        // Given a whitespace-only email and an empty return URL
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "   "
        configuration.returnURL = ""

        // When the config is built
        let config = MobileSession.Config(configuration: configuration)

        // Then neither counts as present
        XCTAssertEqual(config.paymentElementConfig.defaultBillingDetails.email, false)
        XCTAssertEqual(config.paymentElementConfig.hasReturnUrl, false)
    }

    func testConfig_cardBrandAcceptance() {
        // An allow list maps to the allowed filter with its brands
        var configuration = PaymentSheet.Configuration()
        configuration.cardBrandAcceptance = .allowed(brands: [.visa, .mastercard, .discover])
        XCTAssertEqual(
            MobileSession.Config(configuration: configuration).paymentElementConfig.cardBrandAcceptance,
            .init(filter: .allowed, brands: [.visa, .mastercard, .discover])
        )

        // Accepting all brands sends no brands
        configuration.cardBrandAcceptance = .all
        XCTAssertEqual(
            MobileSession.Config(configuration: configuration).paymentElementConfig.cardBrandAcceptance,
            .init(filter: .all, brands: [])
        )
    }

    func testDeviceSupportsNativeLink() {
        // In test mode, native Link doesn't need attestation
        XCTAssertTrue(MobileSession.Config.deviceSupportsNativeLink(apiClient: STPAPIClient(publishableKey: "pk_test_123")))

        // The playground override wins
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = false
        XCTAssertFalse(MobileSession.Config.deviceSupportsNativeLink(apiClient: STPAPIClient(publishableKey: "pk_test_123")))
    }

    func testConfigHeaders_flag() {
        let configuration = PaymentSheet.Configuration()

        // With the flag off, no header is sent
        XCTAssertEqual(MobileSession.configHeaders(for: configuration), [:])

        // With the flag on, the header is sent
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let headers = MobileSession.configHeaders(for: configuration)
        XCTAssertEqual(Array(headers.keys), ["X-Stripe-Mobile-Config"])
        XCTAssertEqual(headers["X-Stripe-Mobile-Config"], try? MobileSession.encodeHeaderValue(MobileSession.Config(configuration: configuration)))
    }

    // MARK: - Sidecar decoding

    func testSidecar_present() {
        // Given the flag is on and the response has a sidecar
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(mobileSession: ["payment_method_availability": ["payment_method_types": ["card", "klarna"], "link_enabled": true] as [String: Any]])

        // Then it's decoded
        XCTAssertEqual(elementsSession.mobileSession?.paymentMethodAvailability?.paymentMethodTypes, ["card", "klarna"])
        XCTAssertEqual(elementsSession.mobileSession?.paymentMethodAvailability?.linkEnabled, true)
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionDecodeFailed.rawValue))
    }

    func testSidecar_presentWithoutAvailability() {
        // Given the flag is on and the sidecar is empty
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(mobileSession: [:])

        // Then the session decodes with no availability
        XCTAssertNotNil(elementsSession.mobileSession)
        XCTAssertNil(elementsSession.mobileSession?.paymentMethodAvailability)
    }

    func testSidecar_absent() {
        // Given the flag is on and the response has no sidecar
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(mobileSession: nil)

        // Then there's no server availability and no error
        XCTAssertNil(elementsSession.mobileSession)
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionDecodeFailed.rawValue))
    }

    func testSidecar_malformed() {
        // Given the flag is on and the sidecar has the wrong shape
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(mobileSession: ["payment_method_availability": ["payment_method_types": "card"]])

        // Then the elements session still loads, without server availability
        XCTAssertNil(elementsSession.mobileSession)
        // ...and an error is logged
        XCTAssertTrue(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionDecodeFailed.rawValue))
    }

    func testSidecar_notAnObject() {
        // Given the flag is on and the sidecar isn't a JSON object
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(mobileSession: "card")

        // Then the elements session still loads, without server availability, and an error is logged
        XCTAssertNil(elementsSession.mobileSession)
        XCTAssertTrue(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionDecodeFailed.rawValue))
    }

    func testSidecar_flagOff() {
        // Given the flag is off and the response has a sidecar
        let elementsSession = makeElementsSession(mobileSession: ["payment_method_availability": ["payment_method_types": ["card"], "link_enabled": true] as [String: Any]])

        // Then it isn't decoded
        XCTAssertNil(elementsSession.mobileSession)
    }

    // MARK: - Helpers

    private var loggedEvents: [String] {
        STPAnalyticsClient.sharedClient._testLogHistory.compactMap { $0["event"] as? String }
    }

    private func makeElementsSession(mobileSession: Any?) -> STPElementsSession {
        var json = STPTestUtils.jsonNamed("ElementsSession")!
        json["mobile_session"] = mobileSession
        return STPElementsSession.decodedObject(fromAPIResponse: json)!
    }
}

class MobileSessionHeaderStubbedTests: APIStubbedTestCase {

    func testPaymentSheetLoadSendsConfigHeader() async throws {
        // Given the flag is on
        enableFlag()
        let sentHeaders = stubElementsSessionsCapturingConfigHeader()
        StubbedBackend.stubLookup()
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = stubbedAPIClient()

        // When PaymentSheet loads
        _ = try await PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: ._testValue(configuration: configuration),
            integrationShape: .paymentSheet
        )

        // Then its elements/sessions request carries the config header
        let header = try XCTUnwrap(sentHeaders.values.first.flatMap { $0 })
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(header.utf8)) as? [String: Any])
        XCTAssertNotNil(json["spec_hash"])
    }

    func testElementsSessionOmitsConfigHeaderByDefault() async throws {
        // Given the flag is on
        enableFlag()
        let sentHeaders = stubElementsSessionsCapturingConfigHeader()

        // When elements/sessions is fetched without opting in, as CustomerSheet and the Link brand fetch do
        _ = try await stubbedAPIClient().retrieveElementsSession(
            paymentIntentClientSecret: "pi_12345_secret_54321",
            clientDefaultPaymentMethod: nil,
            configuration: PaymentSheet.Configuration(),
            customerProvider: CustomerProvider(customer: nil)
        )

        // Then the request has no config header
        XCTAssertEqual(sentHeaders.values, [nil])
    }

    private func enableFlag() {
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        addTeardownBlock {
            PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = false
        }
    }

    /// Stubs elements/sessions and records the `X-Stripe-Mobile-Config` header of each request.
    private func stubElementsSessionsCapturingConfigHeader() -> SentHeaders {
        let sentHeaders = SentHeaders()
        stub { $0.url?.path == "/v1/elements/sessions" } response: { request in
            sentHeaders.values.append(request.value(forHTTPHeaderField: MobileSession.configHeaderName))
            let data = StubbedBackend.updatePaymentMethodDetail(
                data: try! FileMock.elementsSessionsPaymentMethod_200.data(),
                variables: ["<paymentMethods>": "\"card\"", "<currency>": "\"usd\""]
            )
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
        return sentHeaders
    }

    private final class SentHeaders {
        var values: [String?] = []
    }
}
