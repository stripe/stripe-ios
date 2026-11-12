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

    private var availabilityLogs: [String] = []

    override func setUp() {
        super.setUp()
        STPAnalyticsClient.sharedClient._testLogHistory = []
        availabilityLogs = []
        PaymentSheetLoader.availabilityLogger = { [weak self] in self?.availabilityLogs.append($0) }
    }

    override func tearDown() {
        PaymentSheetLoader.availabilityLogger = { print($0) }
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = false
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
        STPLocalizationUtils.overrideLanguage(to: nil)
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
        config.environment = .init(hasFinancialConnectionsSdk: true, deviceSupportsNativeLink: true, displayLanguage: "fr")
        let header = try MobileSession.encodeHeaderValue(config)

        // Then it matches the golden JSON, which is the spec's fully populated iOS example
        XCTAssertEqual(
            header,
            #"{"environment":{"device_supports_native_link":true,"display_language":"fr","has_financial_connections_sdk":true},"payment_element_config":{"allows_delayed_payment_methods":true,"billing_details_collection":{"address":"full","attach_defaults_to_payment_method":true,"email":"always","name":"always","phone":"never"},"card_brand_acceptance":{"brands":["amex"],"filter":"disallowed"},"default_billing_details":{"email":true},"has_return_url":true,"link":{"display_mode":"wallet_button_hidden"},"payment_method_order":["card","external_paypal"]},"spec_hash":"8307abc8"}"#
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
        config.environment = .init(hasFinancialConnectionsSdk: false, deviceSupportsNativeLink: false, displayLanguage: "en")
        let header = try MobileSession.encodeHeaderValue(config)

        // Then it matches the golden JSON, with every field present
        XCTAssertEqual(
            header,
            #"{"environment":{"device_supports_native_link":false,"display_language":"en","has_financial_connections_sdk":false},"payment_element_config":{"allows_delayed_payment_methods":false,"billing_details_collection":{"address":"automatic","attach_defaults_to_payment_method":false,"email":"automatic","name":"automatic","phone":"automatic"},"card_brand_acceptance":{"brands":[],"filter":"all"},"default_billing_details":{"email":false},"has_return_url":false,"link":{"display_mode":"automatic"},"payment_method_order":[]},"spec_hash":"8307abc8"}"#
        )
    }

    func testConfigHeader_escapesNonASCII() throws {
        // Given a config with non-ASCII payment method types, including one outside the Basic Multilingual Plane.
        // `Config(configuration:)` trims these, so set them directly.
        var config = MobileSession.Config(configuration: PaymentSheet.Configuration())
        config.paymentElementConfig.paymentMethodOrder = ["café", "😀"]

        // When it's encoded
        let header = try MobileSession.encodeHeaderValue(config)

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

    func testConfig_trimsPaymentMethodOrder() {
        // Given a paymentMethodOrder with duplicates, entries that can't be payment method types, and a type the SDK doesn't know
        var configuration = PaymentSheet.Configuration()
        configuration.paymentMethodOrder = ["card", "CARD", "café", "", "demo_pay", String(repeating: "a", count: 41), "external_paypal", "cpmt_1AbC"]

        // When the config is built
        let config = MobileSession.Config(configuration: configuration)

        // Then only the first copy of each well-formed entry is kept, including the unknown type
        XCTAssertEqual(config.paymentElementConfig.paymentMethodOrder, ["card", "demo_pay", "external_paypal", "cpmt_1AbC"])
    }

    func testConfigHeader_worstCaseStaysUnder2KB() throws {
        // Given a configuration with every field at its largest: a long paymentMethodOrder of the longest entries,
        // every card brand, and a long display language
        STPLocalizationUtils.overrideLanguage(to: "zh-HK")
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "foo://bar"
        configuration.defaultBillingDetails.email = "jane@example.com"
        configuration.billingDetailsCollectionConfiguration.address = .automatic
        configuration.link = .init(display: .walletButtonHidden)
        configuration.cardBrandAcceptance = .disallowed(brands: [.visa, .mastercard, .amex, .discover])
        configuration.paymentMethodOrder = (0..<500).map { "cpmt_" + String(repeating: "x", count: 32) + String(format: "%03d", $0) }

        // When it's encoded
        let header = try MobileSession.encodeHeaderValue(MobileSession.Config(configuration: configuration))

        // Then it's under 2KB, a quarter of the server's 8KB limit per header
        XCTAssertLessThan(header.utf8.count, 2048)
        XCTAssertTrue(header.contains(#""display_language":"zh-Hant-HK""#))
    }

    func testConfig_displayLanguage() throws {
        // Given no language override
        let configuration = PaymentSheet.Configuration()

        // Then the display language is the language the SDK's own strings render in
        let sdkLanguage = try XCTUnwrap(StripePaymentSheetBundleLocator.resourcesBundle.preferredLocalizations.first.map { Locale(identifier: $0).toLanguageTag() })
        XCTAssertFalse(sdkLanguage.isEmpty)
        XCTAssertEqual(MobileSession.Config(configuration: configuration).environment.displayLanguage, sdkLanguage)

        // When the SDK's language is overridden
        STPLocalizationUtils.overrideLanguage(to: "fr")

        // Then the display language follows it
        XCTAssertEqual(MobileSession.Config(configuration: configuration).environment.displayLanguage, "fr")
        // ...and Traditional Chinese keeps its script, like the top-level locale
        STPLocalizationUtils.overrideLanguage(to: "zh-HK")
        XCTAssertEqual(MobileSession.Config(configuration: configuration).environment.displayLanguage, "zh-Hant-HK")

        // When the override names no language
        for override in ["", "  ", "Base"] {
            STPLocalizationUtils.overrideLanguage(to: override)

            // Then the display language is still the bundle's language, never empty
            XCTAssertEqual(MobileSession.Config(configuration: configuration).environment.displayLanguage, sdkLanguage, "override: \(override)")
        }
    }

    func testConfigHeader_includesDisplayLanguage() throws {
        // Given the SDK's language is overridden to French
        STPLocalizationUtils.overrideLanguage(to: "fr")

        // When the header is encoded
        let header = try MobileSession.encodeHeaderValue(MobileSession.Config(configuration: PaymentSheet.Configuration()))

        // Then it carries the display language
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(header.utf8)) as? [String: Any])
        XCTAssertEqual(json[jsonDict: "environment"]?["display_language"] as? String, "fr")
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

    // MARK: - filteredPaymentMethodTypes

    func testFilteredPaymentMethodTypes_usesServerList() {
        // Given the flag is on and the server returns an order that differs from the local logic
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        var configuration = makeConfiguration()
        configuration.paymentMethodOrder = ["card"]
        let elementsSession = makeElementsSession(
            paymentMethodTypes: ["card", "klarna"],
            externalPaymentMethodTypes: ["external_paypal"],
            mobileSession: ["payment_method_availability": ["payment_method_types": ["external_paypal", "klarna", "card"], "link_enabled": true] as [String: Any]]
        )

        // When filtering
        let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: configuration)

        // Then the server's list is used exactly, without reapplying paymentMethodOrder
        XCTAssertEqual(paymentMethodTypes.map { $0.identifier }, ["external_paypal", "klarna", "card"])
        // ...and the mismatch with the local result is logged
        let mismatch = STPAnalyticsClient.sharedClient._testLogHistory.first {
            $0["event"] as? String == STPAnalyticEvent.paymentSheetMobileSessionAvailabilityMismatch.rawValue
        }
        XCTAssertEqual(mismatch?["server_payment_method_types"] as? [String], ["external_paypal", "klarna", "card"])
        XCTAssertEqual(mismatch?["local_payment_method_types"] as? [String], ["card", "klarna", "external_paypal"])
    }

    func testFilteredPaymentMethodTypes_matchingServerListDoesNotLogMismatch() {
        // Given the flag is on and the server agrees with the local logic, for payment methods and for Link
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let configuration = makeConfiguration()
        let linkEnabled = localLinkEnabled(paymentMethodTypes: ["card", "klarna"], configuration: configuration)
        let elementsSession = makeElementsSession(
            paymentMethodTypes: ["card", "klarna"],
            mobileSession: ["payment_method_availability": ["payment_method_types": ["card", "klarna"], "link_enabled": linkEnabled] as [String: Any]]
        )

        // When filtering
        let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: configuration)

        // Then the result is the same and no mismatch is logged
        XCTAssertEqual(paymentMethodTypes.map { $0.identifier }, ["card", "klarna"])
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionAvailabilityMismatch.rawValue))
    }

    func testFilteredPaymentMethodTypes_instantDebitsLastDoesNotLogMismatch() {
        // Given the flag is on and Instant Debits is available
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        var json = STPTestUtils.jsonNamed("ElementsSession")!
        json[jsonDict: "payment_method_preference"]?["ordered_payment_method_types"] = ["card", "link", "klarna", "affirm", "cashapp"]
        json[jsonDict: "link_settings"]?["link_mode"] = "LINK_PAYMENT_METHOD"
        json[jsonDict: "link_settings"]?["link_supported_payment_methods_onboarding_enabled"] = ["INSTANT_DEBITS"]
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "foo://bar"
        let localLinkEnabled = PaymentSheet.linkDisabledReasons(elementsSession: STPElementsSession.decodedObject(fromAPIResponse: json)!, configuration: configuration).isEmpty
        // ...and the server puts the bank option last
        let serverPaymentMethodTypes = ["card", "klarna", "affirm", "cashapp", "instant_debits"]
        json["mobile_session"] = ["payment_method_availability": ["payment_method_types": serverPaymentMethodTypes, "link_enabled": localLinkEnabled] as [String: Any]]
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: json)!

        // When filtering
        let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: configuration)

        // Then the local logic agrees on the order, so no mismatch is logged
        XCTAssertEqual(paymentMethodTypes.map { $0.identifier }, serverPaymentMethodTypes)
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionAvailabilityMismatch.rawValue))
    }

    func testFilteredPaymentMethodTypes_logsLinkMismatch() {
        // Given the flag is on and the server agrees on payment methods but not on Link
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let configuration = makeConfiguration()
        let localLinkEnabled = localLinkEnabled(paymentMethodTypes: ["card", "klarna"], configuration: configuration)
        let elementsSession = makeElementsSession(
            paymentMethodTypes: ["card", "klarna"],
            mobileSession: ["payment_method_availability": ["payment_method_types": ["card", "klarna"], "link_enabled": !localLinkEnabled] as [String: Any]]
        )

        // When filtering
        _ = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: configuration)

        // Then the Link mismatch is logged
        let mismatch = STPAnalyticsClient.sharedClient._testLogHistory.first {
            $0["event"] as? String == STPAnalyticEvent.paymentSheetMobileSessionAvailabilityMismatch.rawValue
        }
        XCTAssertEqual(mismatch?["server_link_enabled"] as? Bool, !localLinkEnabled)
        XCTAssertEqual(mismatch?["local_link_enabled"] as? Bool, localLinkEnabled)
    }

    // MARK: - Link

    func testIsLinkEnabled_usesServerLinkEnabled() {
        // Given the flag is on
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let configuration = makeConfiguration()

        // Then Link is enabled exactly when the server enables it
        for linkEnabled in [true, false] {
            let elementsSession = makeElementsSession(
                mobileSession: ["payment_method_availability": ["payment_method_types": ["card"], "link_enabled": linkEnabled] as [String: Any]]
            )
            XCTAssertEqual(PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration), linkEnabled, "link_enabled: \(linkEnabled)")
        }
    }

    func testIsLinkEnabled_flagOffUsesLocalLogic() {
        // Given a session where the server disagrees with the local logic on Link
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let configuration = makeConfiguration()
        let localLinkEnabled = localLinkEnabled(paymentMethodTypes: ["card"], configuration: configuration)
        let elementsSession = makeElementsSession(
            mobileSession: ["payment_method_availability": ["payment_method_types": ["card"], "link_enabled": !localLinkEnabled] as [String: Any]]
        )

        // When the flag is off
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = false

        // Then the local logic decides
        XCTAssertEqual(PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration), localLinkEnabled)
    }

    func testFilteredPaymentMethodTypes_mapsSyntheticTypes() {
        // Given the flag is on and the server returns synthetic types
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(
            mobileSession: ["payment_method_availability": ["payment_method_types": ["card", "instant_debits", "link_card_brand"], "link_enabled": true] as [String: Any]]
        )

        // Then they map to their PaymentMethodType cases
        XCTAssertEqual(
            filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: makeConfiguration()),
            [.stripe(.card), .instantDebits, .linkCardBrand]
        )
    }

    func testFilteredPaymentMethodTypes_assertsAndDropsUnrenderableTypes() {
        // Given the flag is on
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        // ...and types the client can't render: an unknown type, an EPM missing from the session, and a CPM the merchant didn't configure
        for unrenderableType in ["not_a_real_type", "external_venmo", "cpmt_123"] {
            STPAnalyticsClient.sharedClient._testLogHistory = []
            STPAssertTestUtil.shouldSuppressNextSTPAlert = true
            let elementsSession = makeElementsSession(
                mobileSession: ["payment_method_availability": ["payment_method_types": ["card", unrenderableType], "link_enabled": true] as [String: Any]]
            )

            // When filtering
            let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: makeConfiguration())

            // Then it asserts, since the server should never return these
            XCTAssertEqual(STPAssertTestUtil.lastAssertMessage, "Server returned a payment method type the client can't render: \(unrenderableType)")
            // ...drops the type
            XCTAssertEqual(paymentMethodTypes.map { $0.identifier }, ["card"])
            // ...and logs it
            let dropped = STPAnalyticsClient.sharedClient._testLogHistory
                .filter { $0["event"] as? String == STPAnalyticEvent.paymentSheetMobileSessionPaymentMethodDropped.rawValue }
                .compactMap { $0["payment_method_type"] as? String }
            XCTAssertEqual(dropped, [unrenderableType])
        }
    }

    func testFilteredPaymentMethodTypes_mapsConfiguredCustomPaymentMethod() {
        // Given the flag is on and the merchant configured a CPM that's in the session
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        var configuration = makeConfiguration()
        configuration.customPaymentMethodConfiguration = .init(customPaymentMethods: [.init(id: "cpmt_123", subtitle: nil)], customPaymentMethodConfirmHandler: { _, _ in
            XCTFail()
            return .canceled
        })
        let elementsSession = makeElementsSession(
            customPaymentMethodTypes: ["cpmt_123"],
            mobileSession: ["payment_method_availability": ["payment_method_types": ["card", "cpmt_123"], "link_enabled": true] as [String: Any]]
        )

        // When filtering
        let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: configuration)

        // Then the CPM maps to an external payment method
        XCTAssertEqual(paymentMethodTypes.count, 2)
        XCTAssertEqual(paymentMethodTypes.first, .stripe(.card))
        guard case .external(let externalPaymentOption) = paymentMethodTypes.last else {
            return XCTFail("Expected an external payment method, got \(String(describing: paymentMethodTypes.last))")
        }
        XCTAssertEqual(externalPaymentOption.type, "cpmt_123")
        XCTAssertEqual(externalPaymentOption.displayText, "BufoPay")
        // ...and it isn't dropped
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionPaymentMethodDropped.rawValue))
    }

    func testFilteredPaymentMethodTypes_fallsBackWhenServerListAbsent() {
        // Given the flag is on but the sidecar has no availability
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        var configuration = makeConfiguration()
        configuration.paymentMethodOrder = ["klarna"]
        let elementsSession = makeElementsSession(paymentMethodTypes: ["card", "klarna"], mobileSession: [:])

        // Then the local logic runs, including paymentMethodOrder
        XCTAssertEqual(
            filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: configuration).map { $0.identifier },
            ["klarna", "card"]
        )
    }

    func testFilteredPaymentMethodTypes_flagOffIgnoresServerList() {
        // Given a session that has server availability
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(
            paymentMethodTypes: ["card", "klarna"],
            mobileSession: ["payment_method_availability": ["payment_method_types": ["klarna"], "link_enabled": true] as [String: Any]]
        )

        // When the flag is off at filtering time
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = false

        // Then the local logic runs unchanged
        XCTAssertEqual(
            filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: makeConfiguration()).map { $0.identifier },
            ["card", "klarna"]
        )
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionAvailabilityMismatch.rawValue))
    }

    // MARK: - Server-driven payment methods

    func testSidecar_decodesPaymentMethods() throws {
        // Given the flag is on and the sidecar describes a payment method
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(mobileSession: serverDrivenMobileSession(types: ["card", "demo_pay"], paymentMethods: [ServerDrivenPaymentMethodFixtures.json()]))

        // Then it's decoded
        XCTAssertEqual(elementsSession.mobileSession?.paymentMethods, [try ServerDrivenPaymentMethodFixtures.paymentMethod()])
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionDecodeFailed.rawValue))
    }

    func testFilteredPaymentMethodTypes_mapsServerDrivenPaymentMethods() throws {
        // Given the flag is on and the server offers a type the SDK doesn't know, with its description
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let configuration = makeConfiguration()
        let elementsSession = makeElementsSession(
            mobileSession: serverDrivenMobileSession(
                types: ["demo_pay", "card"],
                linkEnabled: localLinkEnabled(paymentMethodTypes: ["card"], configuration: configuration),
                paymentMethods: [ServerDrivenPaymentMethodFixtures.json()]
            )
        )

        // When filtering
        let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: configuration)

        // Then the type maps to a server-driven payment method, in the server's order
        XCTAssertEqual(paymentMethodTypes, [.serverDriven(try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod()), .stripe(.card)])
        XCTAssertEqual(paymentMethodTypes.first?.displayName, "Demo Pay")
        // ...without a mismatch, since the local logic can't offer it
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionAvailabilityMismatch.rawValue))
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionPaymentMethodDropped.rawValue))
    }

    func testFilteredPaymentMethodTypes_serverDescriptionWinsOverNativeType() throws {
        // Given the flag is on and the server describes a type the SDK supports natively
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let configuration = makeConfiguration()
        let elementsSession = makeElementsSession(
            paymentMethodTypes: ["card", "klarna"],
            mobileSession: serverDrivenMobileSession(
                types: ["card", "klarna"],
                linkEnabled: localLinkEnabled(paymentMethodTypes: ["card", "klarna"], configuration: configuration),
                paymentMethods: [ServerDrivenPaymentMethodFixtures.json(type: "klarna")]
            )
        )

        // When filtering
        let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: configuration)

        // Then the server's description is used
        XCTAssertEqual(paymentMethodTypes.map { $0.identifier }, ["card", "klarna"])
        guard case .serverDriven = paymentMethodTypes.last else {
            return XCTFail("Expected klarna to be server-driven, got \(String(describing: paymentMethodTypes.last))")
        }
        // ...and it's left out of the shadow comparison, so there's no mismatch
        XCTAssertFalse(loggedEvents.contains(STPAnalyticEvent.paymentSheetMobileSessionAvailabilityMismatch.rawValue))
    }

    func testFilteredPaymentMethodTypes_dropsUnrenderableEntriesWithoutAsserting() {
        // Given the flag is on
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        // ...and entries this SDK can't render, one value at a time
        let cases: [(String, (inout [String: Any]) -> Void)] = [
            ("form_element:unparsable", { $0["form"] = ["elements": [["type": "billing_address"]]] }),
            ("next_action:unparsable", { $0[jsonDict: "confirm"]?["next_actions"] = ["display_qr_code"] }),
            ("mandate_data:online_inferred", { $0[jsonDict: "confirm"]?["mandate_data"] = "online_inferred" }),
            ("icon_rendering:unparsable", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["rendering"] = "vector" }),
        ]
        for (expectedValue, modify) in cases {
            STPAnalyticsClient.sharedClient._testLogHistory = []
            STPAssertTestUtil.lastAssertMessage = ""
            let elementsSession = makeElementsSession(
                mobileSession: serverDrivenMobileSession(types: ["card", "demo_pay"], paymentMethods: [ServerDrivenPaymentMethodFixtures.json(modify)])
            )

            // When filtering
            let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: makeConfiguration())

            // Then the entry is dropped
            XCTAssertEqual(paymentMethodTypes.map { $0.identifier }, ["card"], expectedValue)
            // ...without asserting, since an unsuppressed assertion would fail the test
            XCTAssertEqual(STPAssertTestUtil.lastAssertMessage, "", expectedValue)
            // ...and reported once, with the value it couldn't render
            let dropped = droppedPaymentMethodEvents
            XCTAssertEqual(dropped.map { $0["payment_method_type"] as? String }, ["demo_pay"], expectedValue)
            XCTAssertEqual(dropped.map { $0["unsupported_value"] as? String }, [expectedValue])
        }
    }

    func testFilteredPaymentMethodTypes_unrenderableEntryFallsBackToNativeType() {
        // Given the flag is on and the server describes a native type in a way this SDK can't render
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(
            paymentMethodTypes: ["card", "klarna"],
            mobileSession: serverDrivenMobileSession(
                types: ["card", "klarna"],
                paymentMethods: [ServerDrivenPaymentMethodFixtures.json(type: "klarna") { $0[jsonDict: "confirm"]?["mandate_data"] = "online_inferred" }]
            )
        )

        // When filtering
        let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: makeConfiguration())

        // Then the native type is used
        XCTAssertEqual(paymentMethodTypes, [.stripe(.card), .stripe(.klarna)])
        // ...and the entry is still reported
        XCTAssertEqual(droppedPaymentMethodEvents.map { $0["unsupported_value"] as? String }, ["mandate_data:online_inferred"])
    }

    func testServerDrivenPaymentMethods_checkoutDropsEntries() {
        // Given the flag is on and the session describes a payment method
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(
            mobileSession: serverDrivenMobileSession(types: ["card", "demo_pay"], paymentMethods: [ServerDrivenPaymentMethodFixtures.json()])
        )

        // When the intent is a Checkout Session, which doesn't support server-driven payment methods yet
        let (renderable, unrenderableTypes) = PaymentSheet.PaymentMethodType.serverDrivenPaymentMethods(intent: ._testCheckoutSession(), elementsSession: elementsSession)

        // Then the entry is dropped and reported
        XCTAssertEqual(renderable, [:])
        XCTAssertEqual(unrenderableTypes, ["demo_pay"])
        XCTAssertEqual(droppedPaymentMethodEvents.map { $0["unsupported_value"] as? String }, ["intent:checkout"])
    }

    func testFilteredPaymentMethodTypes_typeWithoutEntryStillAsserts() {
        // Given the flag is on and the server offers an unknown type without describing it
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        let elementsSession = makeElementsSession(
            mobileSession: serverDrivenMobileSession(types: ["card", "demo_pay"], paymentMethods: [ServerDrivenPaymentMethodFixtures.json(type: "other_pay")])
        )

        // When filtering
        let paymentMethodTypes = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: makeConfiguration())

        // Then it's dropped with an assertion, since that's a server bug
        XCTAssertEqual(paymentMethodTypes.map { $0.identifier }, ["card"])
        XCTAssertEqual(STPAssertTestUtil.lastAssertMessage, "Server returned a payment method type the client can't render: demo_pay")
    }

    func testFilteredPaymentMethodTypes_flagOffIgnoresServerDrivenPaymentMethods() {
        // Given a session that describes a server-driven payment method
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(
            paymentMethodTypes: ["card", "klarna"],
            mobileSession: serverDrivenMobileSession(types: ["demo_pay", "klarna"], paymentMethods: [ServerDrivenPaymentMethodFixtures.json(), ServerDrivenPaymentMethodFixtures.json(type: "klarna")])
        )

        // When the flag is off at filtering time
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = false

        // Then the local logic runs, with no server-driven payment methods
        XCTAssertEqual(filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: makeConfiguration()), [.stripe(.card), .stripe(.klarna)])
        // ...and no header is sent
        XCTAssertEqual(MobileSession.configHeaders(for: makeConfiguration()), [:])
    }

    // MARK: - Availability logs

    func testLogAvailabilityMessages_logsServerMessages() {
        // Given the flag is on and the server sends availability with log messages
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let logMessages = ["[Stripe SDK]: PaymentSheet could not offer wechat_pay:\n\t* Unsupported.", "[Stripe SDK]: Another message"]
        let elementsSession = makeElementsSession(
            unactivatedPaymentMethodTypes: ["klarna"],
            mobileSession: [
                "payment_method_availability": ["payment_method_types": ["card"], "link_enabled": true] as [String: Any],
                "log_messages": logMessages,
            ] as [String: Any]
        )

        // When the session is loaded
        PaymentSheetLoader.logAvailabilityMessages(elementsSession: elementsSession)

        // Then each server message is logged verbatim, without the local unactivated warning
        XCTAssertEqual(availabilityLogs, logMessages)
    }

    func testLogAvailabilityMessages_serverAvailabilityWithoutMessages() {
        // Given the flag is on and the server sends availability without log messages, as in live mode
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(
            unactivatedPaymentMethodTypes: ["klarna"],
            mobileSession: ["payment_method_availability": ["payment_method_types": ["card"], "link_enabled": true] as [String: Any]]
        )

        // When the session is loaded
        PaymentSheetLoader.logAvailabilityMessages(elementsSession: elementsSession)

        // Then nothing is logged
        XCTAssertEqual(availabilityLogs, [])
    }

    func testFilteredPaymentMethodTypes_skipsLocalLogsWithServerAvailability() {
        // Given the flag is on, the server sends availability, and the local logic would drop wechat_pay
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(
            paymentMethodTypes: ["card", "wechat_pay"],
            mobileSession: ["payment_method_availability": ["payment_method_types": ["card"], "link_enabled": true] as [String: Any]]
        )

        // When filtering with logging on
        _ = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: makeConfiguration(), logAvailability: true)

        // Then the local logic logs nothing
        XCTAssertEqual(availabilityLogs, [])
    }

    func testAvailabilityLogs_unchangedWithoutServerAvailability() {
        // Given the flag is on but the sidecar has log messages and no availability
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        let elementsSession = makeElementsSession(
            paymentMethodTypes: ["card", "wechat_pay"],
            unactivatedPaymentMethodTypes: ["klarna"],
            mobileSession: ["log_messages": ["[Stripe SDK]: Server message"]]
        )

        // When the session is loaded and filtered with logging on
        PaymentSheetLoader.logAvailabilityMessages(elementsSession: elementsSession)
        _ = filteredPaymentMethodTypes(elementsSession: elementsSession, configuration: makeConfiguration(), logAvailability: true)

        // Then the local logs are logged as before
        XCTAssertTrue(availabilityLogs.contains { $0.hasPrefix("[Stripe SDK] Warning: Your Intent contains the following payment method types which are activated for test mode but not activated for live mode: Klarna.") })
        XCTAssertTrue(availabilityLogs.contains { $0.hasPrefix("[Stripe SDK]: PaymentSheet could not offer WeChat Pay:") })
        // ...and the server's messages aren't
        XCTAssertFalse(availabilityLogs.contains("[Stripe SDK]: Server message"))
    }

    // MARK: - Helpers

    private var loggedEvents: [String] {
        STPAnalyticsClient.sharedClient._testLogHistory.compactMap { $0["event"] as? String }
    }

    private var droppedPaymentMethodEvents: [[String: Any]] {
        STPAnalyticsClient.sharedClient._testLogHistory.filter {
            $0["event"] as? String == STPAnalyticEvent.paymentSheetMobileSessionPaymentMethodDropped.rawValue
        }
    }

    private func serverDrivenMobileSession(types: [String], linkEnabled: Bool = true, paymentMethods: [[String: Any]]) -> [String: Any] {
        return [
            "payment_method_availability": ["payment_method_types": types, "link_enabled": linkEnabled] as [String: Any],
            "payment_methods": paymentMethods,
        ]
    }

    private func makeConfiguration() -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_paypal"], externalPaymentMethodConfirmHandler: { _, _ in
            XCTFail()
            return .canceled
        })
        return configuration
    }

    private func makeElementsSession(
        paymentMethodTypes: [String] = ["card"],
        externalPaymentMethodTypes: [String] = [],
        customPaymentMethodTypes: [String] = [],
        unactivatedPaymentMethodTypes: [String] = [],
        mobileSession: Any?
    ) -> STPElementsSession {
        var json = STPTestUtils.jsonNamed("ElementsSession")!
        json[jsonDict: "payment_method_preference"]?["ordered_payment_method_types"] = paymentMethodTypes
        json["unactivated_payment_method_types"] = unactivatedPaymentMethodTypes
        json["external_payment_method_data"] = externalPaymentMethodTypes.map {
            [
                "type": $0,
                "label": $0,
                "light_image_url": "https://test.com",
                "dark_image_url": "https://test.com",
            ]
        }
        json["custom_payment_method_data"] = customPaymentMethodTypes.map {
            [
                "type": $0,
                "display_name": "BufoPay",
                "logo_url": "https://test.com",
                "is_preset": false,
            ] as [String: Any]
        }
        json["mobile_session"] = mobileSession
        return STPElementsSession.decodedObject(fromAPIResponse: json)!
    }

    private func localLinkEnabled(paymentMethodTypes: [String], configuration: PaymentSheet.Configuration) -> Bool {
        let elementsSession = makeElementsSession(paymentMethodTypes: paymentMethodTypes, mobileSession: nil)
        return PaymentSheet.linkDisabledReasons(elementsSession: elementsSession, configuration: configuration).isEmpty
    }

    private func filteredPaymentMethodTypes(elementsSession: STPElementsSession, configuration: PaymentSheet.Configuration, logAvailability: Bool = false) -> [PaymentSheet.PaymentMethodType] {
        let intent = Intent.deferredIntent(
            intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _ in return "" })
        )
        return PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, elementsSession: elementsSession, configuration: configuration, logAvailability: logAvailability)
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
