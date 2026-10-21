//
//  CheckoutTestHelpers.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Combine
import OHHTTPStubs
import OHHTTPStubsSwift
import PassKit
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import UIKit
import XCTest

extension PaymentPagesAPIResponse {
    /// Convenience for fixtures that contain no client-local session state.
    func makePublicSession(
        expressCheckoutConfiguration: ExpressCheckoutElement.Configuration? = nil
    ) -> CheckoutController.Session {
        let configuration = expressCheckoutConfiguration.map { expressConfiguration in
            var configuration = CheckoutController.Configuration(clientSecret: "\(sessionId)_secret_abc", returnURL: "stripe-ios-test://checkout-return")
            configuration.expressCheckoutElement = expressConfiguration
            return configuration
        }
        return CheckoutController.Session(
            apiResponse: self,
            localState: .empty,
            configuration: configuration
        )
    }
}

extension ExpressCheckoutElementUtilities {
    static func availablePaymentMethodsWithoutCheckoutRequirements(
        for elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration
    ) -> [ExpressCheckoutElement.PaymentMethod] {
        availablePaymentMethods(
            for: elementsSession,
            configuration: configuration,
            usesWebLink: false,
            requiresShippingAddress: false,
            billingDetailsCollectionRequired: false
        )
    }

    static func linkDisabledReasonsWithoutCheckoutRequirements(
        for elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration
    ) -> [LinkDisabledReason] {
        linkDisabledReasons(
            for: elementsSession,
            configuration: configuration,
            usesWebLink: false,
            requiresShippingAddress: false,
            billingDetailsCollectionRequired: false
        )
    }
}

extension PaymentPagesAPIResponse {
    static func decode(
        fromAPIResponse response: [AnyHashable: Any]
    ) throws -> PaymentPagesAPIResponse {
        let data = try JSONSerialization.data(withJSONObject: response)
        return try StripeJSONDecoder().decode(PaymentPagesAPIResponse.self, from: data)
    }

}

// MARK: - Emission Recorder

@MainActor
class CheckoutEmissionRecorder {
    var sessions: [CheckoutController.Session] = []
    var loading: [Bool] = []
    private var subscriptions = Set<AnyCancellable>()

    init(_ checkout: CheckoutController) {
        checkout.$session.dropFirst().sink { [weak self] in self?.sessions.append($0) }
            .store(in: &subscriptions)
        checkout.$isUpdating.dropFirst().sink { [weak self] in self?.loading.append($0) }
            .store(in: &subscriptions)
    }
}

// MARK: - Request Recording

enum CheckoutSessionRequestKind: Equatable {
    case initSession
    case updateSession
}

struct CheckoutSessionRequest {
    let kind: CheckoutSessionRequestKind
    let params: [String: String]
}

final class CheckoutSessionRequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _requests: [CheckoutSessionRequest] = []

    var requests: [CheckoutSessionRequest] {
        lock.lock()
        defer { lock.unlock() }
        return _requests
    }

    func append(_ request: CheckoutSessionRequest) {
        lock.lock()
        defer { lock.unlock() }
        _requests.append(request)
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        _requests.removeAll()
    }
}

// MARK: - Shared Helpers

enum CheckoutTestHelpers {

    // MARK: - Base JSON building blocks

    static let minimalElementsSessionJSON: [String: Any] = [
        "session_id": "es_test",
        "merchant_country": "US",
        "payment_method_preference": ["ordered_payment_method_types": ["card"]],
    ]

    static func makeOneTimePriceCheckoutItems(
        currency: String = "usd",
        unitAmount: Int = 1000
    ) -> [[String: Any]] {
        return [
            [
                "key": "checkout_item_test",
                "type": "one_time_price",
                "one_time_price": [
                    "items": [
                        [
                            "inner_item_key": "checkout_item_inner_test",
                            "quantity": 1,
                            "subtotal": unitAmount,
                            "total": unitAmount,
                            "unit_amount": unitAmount,
                            "unit_amount_decimal": String(unitAmount),
                            "tax_amounts": [],
                            "tax_inclusive": 0,
                            "tax_exclusive": 0,
                            "price": [
                                "id": "price_test",
                                "currency": currency,
                                "unit_amount": unitAmount,
                                "product": [
                                    "name": "Test product",
                                    "images": [],
                                ],
                            ],
                        ],
                    ],
                    "subtotal": unitAmount,
                    "total": unitAmount,
                ],
            ],
        ]
    }

    static let baseSessionJSON: [String: Any] = [
        "session_id": "cs_test",
        "object": "checkout.session",
        "livemode": false,
        "mode": "modeless",
        "status": "open",
        "payment_status": "unpaid",
        "payment_method_types": ["card"],
        "currency": "usd",
        "checkout_items": makeOneTimePriceCheckoutItems(),
        "elements_session": minimalElementsSessionJSON,
    ]

    /// Creates a `PaymentPagesAPIResponse` from `baseSessionJSON` with top-level key overrides.
    /// To test field *absence*, mutate `baseSessionJSON` directly instead.
    static func makeSession(_ overrides: [String: Any] = [:]) -> PaymentPagesAPIResponse {
        let json = makeSessionJSON(overrides)
        return try! PaymentPagesAPIResponse.decode(fromAPIResponse: json)
    }

    static func makeSessionWithWalletTypes(
        _ walletTypes: [String],
        applePayPreference: String? = nil,
        linkUseAttestation: Bool? = nil,
        automaticTaxAddressSource: String? = nil,
        customerEmail: String? = nil
    ) -> PaymentPagesAPIResponse {
        var elementsSession: [String: Any] = [
            "session_id": "es_test",
            "merchant_country": "US",
            "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            "ordered_payment_method_types_and_wallets": walletTypes,
        ]
        if let applePayPreference {
            elementsSession["apple_pay_preference"] = applePayPreference
        }
        if let linkUseAttestation {
            elementsSession["link_settings"] = [
                "link_funding_sources": ["CARD"],
                "link_mobile_use_attestation_endpoints": linkUseAttestation,
            ]
        }
        var session: [String: Any] = ["elements_session": elementsSession]
        if let automaticTaxAddressSource {
            session["tax_context"] = [
                "automatic_tax_enabled": true,
                "automatic_tax_address_source": automaticTaxAddressSource,
            ]
        }
        if let customerEmail {
            session["customer_email"] = customerEmail
        }
        return makeSession(session)
    }

    static func makeSessionJSON(_ overrides: [String: Any] = [:]) -> [String: Any] {
        baseSessionJSON.merging(overrides) { _, new in new }
    }

    // MARK: - Checkout-flow helpers

    /// Builds a `CheckoutController.Configuration`, replacing its `apiClient` with one that uses test stubs.
    ///
    /// - Parameters:
    ///   - apiResponse: The Checkout Session response returned by the stubbed `/init` request.
    ///   - configuration: An optional base configuration for test-specific settings.
    ///   - paymentElementConfiguration: The Payment Element configuration to use when the base configuration omits it.
    ///   - stubAllOutgoingRequests: Whether to stub every outgoing API request made by the client, or only the initialization request.
    @MainActor
    static func makeConfiguration(
        apiResponse: PaymentPagesAPIResponse = makeOpenSession(),
        configuration: CheckoutController.Configuration? = nil,
        paymentElementConfiguration: PaymentElement.Configuration? = .init(),
        expressCheckoutElementConfiguration: ExpressCheckoutElement.Configuration? = .init { _ in },
        stubAllOutgoingRequests: Bool = true
    ) -> CheckoutController.Configuration {
        // Use the production Checkout initializer with a test-controlled API client.
        let clientSecret = configuration?.clientSecret ?? "\(apiResponse.sessionId)_secret_abc"
        var resolvedConfiguration = configuration ?? CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        if resolvedConfiguration.paymentElement == nil {
            resolvedConfiguration.paymentElement = paymentElementConfiguration
        }
        if resolvedConfiguration.expressCheckoutElement == nil {
            resolvedConfiguration.expressCheckoutElement = expressCheckoutElementConfiguration
        }
        resolvedConfiguration.apiClient = makeStubbedAPIClient(
            apiResponse: apiResponse,
            clientSecret: clientSecret,
            stubAllOutgoingRequests: stubAllOutgoingRequests
        )
        return resolvedConfiguration
    }

    /// Builds a stubbed Checkout configuration that enables Currency Selector Element.
    @MainActor
    static func makeCurrencySelectorConfiguration(
        apiResponse: PaymentPagesAPIResponse = makeOpenSession(),
        configuration: CheckoutController.Configuration? = nil
    ) -> CheckoutController.Configuration {
        let clientSecret = configuration?.clientSecret ?? "\(apiResponse.sessionId)_secret_abc"
        var resolvedConfiguration = configuration ?? CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        if resolvedConfiguration.currencySelectorElement == nil {
            resolvedConfiguration.currencySelectorElement = .init()
        }
        return makeConfiguration(apiResponse: apiResponse, configuration: resolvedConfiguration)
    }

    @MainActor
    static func makeStubbedAPIClient(
        apiResponse: PaymentPagesAPIResponse = makeOpenSession(),
        clientSecret: String? = nil,
        stubAllOutgoingRequests: Bool = true
    ) -> STPAPIClient {
        let resolvedClientSecret = clientSecret ?? "\(apiResponse.sessionId)_secret_abc"
        let sessionId = CheckoutController.extractSessionId(from: resolvedClientSecret)
        let apiClient = APIStubbedTestCase.stubbedAPIClient()
        apiClient.publishableKey = "pk_test_123"

        // Keep tests offline except for explicitly stubbed Checkout init work.
        if stubAllOutgoingRequests {
            APIStubbedTestCase.stubAllOutgoingRequests()
        }
        StubbedBackend.stubLookup()
        stub(condition: { request in
            let url = request.url?.absoluteString ?? ""
            return url.contains("/v3/fingerprinted/img/payment-methods")
                || url.contains("/ocs-mobile/assets/flags/")
        }) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        stub(condition: { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/checkout_client/\(sessionId)/init"
        }) { _ in
            // Feed CheckoutController(configuration:) the session fixture this test requested.
            var responseJSON = jsonObject(apiResponse.allResponseFields) as? [String: Any] ?? [:]
            responseJSON["session_id"] = responseJSON["session_id"] ?? sessionId
            let data = try! JSONSerialization.data(
                withJSONObject: checkoutClientInitJSON(from: responseJSON, sessionId: sessionId),
                options: []
            )
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
        // Init can trigger a session update (e.g. billing address tax sync); just echo the session back.
        stub(condition: { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/checkout_client/\(sessionId)/update"
        }) { _ in
            var responseJSON = jsonObject(apiResponse.allResponseFields) as? [String: Any] ?? [:]
            responseJSON["session_id"] = responseJSON["session_id"] ?? sessionId
            let data = try! JSONSerialization.data(
                withJSONObject: checkoutClientInitJSON(from: responseJSON, sessionId: sessionId),
                options: []
            )
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
        return apiClient
    }

    /// Stubs Checkout Session `/init` and update requests, recording each request's decoded form params in order.
    ///
    /// Use this when a test needs to verify Checkout initialization, follow-up session updates, or both:
    ///
    /// ```swift
    /// let recorder = CheckoutSessionRequestRecorder()
    /// CheckoutTestHelpers.stubCheckoutSessionRequests(
    ///     sessionId: "cs_test_123",
    ///     requestRecorder: recorder,
    ///     sessionJSON: { CheckoutTestHelpers.openSessionJSON }
    /// )
    ///
    /// _ = try await CheckoutController(configuration: configuration)
    /// XCTAssertEqual(recorder.requests.map(\.kind), [.initSession, .updateSession])
    /// XCTAssertEqual(recorder.requests[1].params["tax_region[country]"], "US")
    /// ```
    static func stubCheckoutSessionRequests(
        sessionId: String,
        requestRecorder: CheckoutSessionRequestRecorder,
        sessionJSON: @escaping () -> [AnyHashable: Any],
        initStatusCode: Int32 = 200,
        updateStatusCode: @escaping (_ requestNumber: Int) -> Int32 = { _ in 200 }
    ) {
        stub { request in
            request.url?.path == "/v1/checkout_client/\(sessionId)/init"
        } response: { request in
            requestRecorder.append(
                .init(
                    kind: .initSession,
                    params: RequestBodyTestHelpers.formEncodedBodyParams(from: request)
                )
            )
            return HTTPStubsResponse(
                jsonObject: checkoutClientInitJSON(
                    from: jsonObject(sessionJSON()) as? [String: Any] ?? [:],
                    sessionId: sessionId
                ),
                statusCode: initStatusCode,
                headers: nil
            )
        }

        stub { request in
            request.url?.path == "/v1/checkout_client/\(sessionId)/update"
        } response: { request in
            requestRecorder.append(
                .init(
                    kind: .updateSession,
                    params: RequestBodyTestHelpers.formEncodedBodyParams(from: request)
                )
            )
            let updateRequestNumber = requestRecorder.requests.filter { $0.kind == .updateSession }.count
            return HTTPStubsResponse(
                jsonObject: checkoutClientInitJSON(
                    from: jsonObject(sessionJSON()) as? [String: Any] ?? [:],
                    sessionId: sessionId
                ),
                statusCode: updateStatusCode(updateRequestNumber),
                headers: nil
            )
        }
    }

    /// Presents the shared Payment Pages test session using the CheckoutClient init field names.
    static func checkoutClientInitJSON(from session: [String: Any], sessionId: String) -> [String: Any] {
        let elementsSession = session["elements_session"] as? [String: Any] ?? [:]
        // Copy only fields returned by CheckoutClient. Legacy-only fields must not make
        // endpoint tests pass when the real backend cannot return them.
        let sharedFields = [
            "livemode", "status", "payment_status", "customer_email", "billing_address_collection",
            "shipping_address_collection", "payment_method_options",
        ]
        var response = session.filter { sharedFields.contains($0.key) }
        response["object"] = "checkout.session"
        response["id"] = session["session_id"] ?? sessionId
        response["ui_mode"] = "mobile_elements"
        response["state"] = "ready"
        response["email_collection"] = "always"
        response["payment_method_collection"] = "auto"
        response["blocked_billing_address_countries"] = []
        response["integration_currency"] = session["currency"] ?? "usd"
        response["presentment_currency"] = session["currency"] ?? "usd"
        response["items"] = session["checkout_items"] ?? []
        response["merchant_info"] = [
            "country": elementsSession["merchant_country"] ?? "US",
            "display_name": elementsSession["business_name"] ?? NSNull(),
        ]
        response["elements_session_id"] = elementsSession["session_id"] ?? "es_test"
        response["ordered_payment_method_types_and_wallets"] =
            elementsSession["ordered_payment_method_types_and_wallets"] ?? session["payment_method_types"] ?? ["card"]
        response["elements_session_config_id"] = elementsSession["config_id"]
        for key in [
            "apple_pay_preference", "google_pay_preference", "flags",
            "experiments_data", "card_brand_choice", "unactivated_payment_method_types",
        ] {
            response[key] = elementsSession[key]
        }
        response["apple_pay_preference"] = response["apple_pay_preference"] ?? "enabled"
        response["google_pay_preference"] = response["google_pay_preference"] ?? "enabled"
        response["unactivated_payment_method_types"] = response["unactivated_payment_method_types"] ?? []
        response["card_brand_choice"] = response["card_brand_choice"] ?? ["eligible": false]
        if let linkSettings = elementsSession["link_settings"] as? [String: Any] {
            let checkoutClientLinkFields = [
                "link_mode", "consumer_found", "link_supported_payment_methods",
                "link_supported_payment_methods_onboarding_enabled", "link_consumer_incentive",
                "link_us_bank_account_funding_source_enabled", "hcaptcha_site_key", "hcaptcha_rqdata",
                "link_payment_session_context", "enable_partner_lookup", "link_brand", "link_funding_sources",
            ]
            response["link_settings"] = linkSettings.filter { checkoutClientLinkFields.contains($0.key) }
        }
        let elementsCustomer = elementsSession["customer"] as? [String: Any]
        let customerSession = elementsCustomer?["customer_session"] as? [String: Any]
        if let customer = session["customer"] as? [String: Any] {
            response["customer"] = [
                "id": customer["id"] ?? NSNull(),
                "payment_methods": customer["payment_methods"] ?? [],
            ]
        } else if let customerId = customerSession?["customer"] as? String {
            response["customer"] = [
                "id": customerId,
                "payment_methods": elementsCustomer?["payment_methods"] ?? [],
            ]
        }
        let offerSave = session["customer_managed_saved_payment_methods_offer_save"] as? [String: Any]
        let customer = session["customer"] as? [String: Any]
        response["saved_payment_method_options"] = [
            "payment_method_save": offerSave?["enabled"] as? Bool == true ? "enabled" : "disabled",
            "payment_method_remove": customer?["can_detach_payment_method"] as? Bool == true ? "enabled" : "disabled",
        ]
        let taxMeta = session["tax_meta"] as? [String: Any]
        let taxContext = session["tax_context"] as? [String: Any]
        if taxMeta?["computation_type"] as? String == "automatic" {
            if let status = taxMeta?["status"] as? String,
               ["complete", "requires_location_inputs"].contains(status) {
                let source = (taxContext?["automatic_tax_address_source"] as? String).map {
                    $0.hasPrefix("session.") ? String($0.dropFirst("session.".count)) : $0
                }
                response["automatic_tax"] = [
                    "enabled": true,
                    "status": status == "complete" ? "ready" : "requires_address",
                    "address_source": source as Any? ?? NSNull(),
                ]
            } else {
                response["automatic_tax"] = NSNull()
            }
        } else {
            response["automatic_tax"] = ["enabled": false, "status": "ready"]
        }
        if let adaptivePricing = session["adaptive_pricing_info"] as? [String: Any],
           let localOptions = adaptivePricing["local_currency_options"] as? [[String: Any]] {
            response["integration_currency"] = adaptivePricing["integration_currency"]
            response["adaptive_pricing_info"] = [
                "integration_currency_option": [
                    "currency": adaptivePricing["integration_currency"] ?? NSNull(),
                    "amount": adaptivePricing["integration_amount"] ?? NSNull(),
                ],
                "local_currency_options": localOptions.map { option in
                    [
                        "currency": option["currency"] ?? NSNull(),
                        "amount": option["amount"] ?? NSNull(),
                        "disclosure": option["disclosure"] ?? NSNull(),
                    ]
                },
            ]
        }
        let items = session["checkout_items"] as? [[String: Any]] ?? []
        let oneTimePrices = items.compactMap { $0["one_time_price"] as? [String: Any] }
        let total = oneTimePrices.reduce(0) { $0 + ($1["total"] as? Int ?? 0) }
        let subtotal = oneTimePrices.reduce(0) { $0 + ($1["subtotal"] as? Int ?? 0) }
        response["total_summary"] = session["total_summary"] ?? [
            "subtotal": subtotal, "total": total, "due": total, "total_tax_amounts": [],
        ]
        if var summary = session["total_summary"] as? [String: Any],
           let taxAmounts = summary["total_tax_amounts"] as? [[String: Any]] {
            summary["total_tax_amounts"] = taxAmounts.map { tax -> [String: Any] in
                var mapped = tax
                mapped.removeValue(forKey: "tax_rate")
                let taxRate = tax["tax_rate"] as? [String: Any]
                mapped["display_name"] = taxRate?["display_name"]
                mapped["percentage"] = taxRate?["percentage"]
                return mapped
            }
            response["total_summary"] = summary
        }
        var paymentResponse: [String: Any] = [:]
        for key in ["payment_intent", "setup_intent"] {
            guard let intent = session[key] as? [String: Any],
                  let id = intent["id"] as? String,
                  let clientSecret = intent["client_secret"] as? String else { continue }
            paymentResponse[key] = ["id": id, "client_secret": clientSecret]
            paymentResponse["status"] = intent["status"]
        }
        if !paymentResponse.isEmpty { response["payment_response"] = paymentResponse }
        return response
    }

    static let openSessionJSON: [AnyHashable: Any] = [
        "session_id": "cs_test_123",
        "object": "checkout.session",
        "livemode": false,
        "mode": "modeless",
        "status": "open",
        "payment_status": "unpaid",
        "payment_method_types": ["card"],
        "currency": "usd",
        "checkout_items": makeOneTimePriceCheckoutItems(),
        "elements_session": minimalElementsSessionJSON,
    ]

    static func makeOpenSession(customerEmail: String? = nil, billingAddressCollection: String? = nil) -> PaymentPagesAPIResponse {
        var json = openSessionJSON
        json["customer_email"] = customerEmail
        json["billing_address_collection"] = billingAddressCollection
        return try! PaymentPagesAPIResponse.decode(fromAPIResponse: json)
    }

    static func makeClosedSession() -> PaymentPagesAPIResponse {
        var json = openSessionJSON
        json["status"] = "complete"
        json["payment_status"] = "paid"
        return try! PaymentPagesAPIResponse.decode(fromAPIResponse: json)
    }

    static func makeOpenSession(allowedCountries: [String]) -> PaymentPagesAPIResponse {
        var json = openSessionJSON
        json["shipping_address_collection"] = ["allowed_countries": allowedCountries]
        return try! PaymentPagesAPIResponse.decode(fromAPIResponse: json)
    }

    static func makeAdaptivePricingSession(
        currency: String = "usd",
        integrationAmount: Int = 1200,
        localAmount: Int = 1000
    ) -> PaymentPagesAPIResponse {
        var json: [AnyHashable: Any] = openSessionJSON
        json["currency"] = currency
        json["checkout_items"] = makeOneTimePriceCheckoutItems(
            currency: currency,
            unitAmount: integrationAmount
        )
        let localCurrencyOption: [AnyHashable: Any] = [
            "currency": "gbp",
            "amount": localAmount,
            "presentment_exchange_rate": "0.776917",
            "disclosure": [
                "caption": "1 USD = 0.7769 GBP (includes 4% conversion fee)",
                "details": "This rate includes a 4% fee to guarantee the exchange rate during checkout.",
            ],
            "conversion_markup_bps": 400,
        ]
        json["adaptive_pricing_info"] = [
            "integration_currency": "usd",
            "integration_amount": integrationAmount,
            "active_presentment_currency": currency,
            "local_currency_options": [localCurrencyOption],
        ]

        return try! PaymentPagesAPIResponse.decode(fromAPIResponse: json)
    }

    private static func jsonObject(_ value: Any) -> Any {
        switch value {
        case let dictionary as [AnyHashable: Any]:
            return Dictionary(uniqueKeysWithValues: dictionary.map { key, value in
                (String(describing: key), jsonObject(value))
            })
        case let dictionary as [String: Any]:
            return Dictionary(uniqueKeysWithValues: dictionary.map { key, value in
                (key, jsonObject(value))
            })
        case let array as [Any]:
            return array.map(jsonObject)
        default:
            return value
        }
    }
}

// MARK: - Apple Pay test doubles

class MockPKPaymentAuthorizationController: PKPaymentAuthorizationController {
    var presentationSucceeds = true

    override func present(completion: (@Sendable (Bool) -> Void)? = nil) {
        completion?(presentationSucceeds)
    }

    override func dismiss(completion: (() -> Void)? = nil) {
        completion?()
    }
}

@MainActor
class MockCheckoutSessionWalletUpdater: CheckoutSessionWalletUpdater {
    private(set) var currentTaxRegion: CheckoutController.Address?
    private(set) var updateCallCount = 0
    private(set) var lastAddress: CheckoutController.Address?
    private(set) var lastCanUpdateWhileSheetPresented: Bool?
    private let sessionToReturn: CheckoutController.Session?
    private let errorToThrow: Error?
    private let suspendsFirstUpdate: Bool
    private var continuation: CheckedContinuation<CheckoutController.Session, Error>?
    private var didSuspend = false

    var isWaiting: Bool {
        continuation != nil
    }

    init(
        sessionToReturn: CheckoutController.Session? = nil,
        errorToThrow: Error? = nil,
        currentTaxRegion: CheckoutController.Address? = nil,
        suspendsFirstUpdate: Bool = false
    ) {
        self.sessionToReturn = sessionToReturn
        self.errorToThrow = errorToThrow
        self.currentTaxRegion = currentTaxRegion
        self.suspendsFirstUpdate = suspendsFirstUpdate
    }

    func updateTaxRegionWithoutEnqueueing(
        address: CheckoutController.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> CheckoutController.Session {
        updateCallCount += 1
        lastAddress = address
        lastCanUpdateWhileSheetPresented = canUpdateWhileSheetPresented
        if let errorToThrow {
            throw errorToThrow
        }
        guard let sessionToReturn else {
            throw CheckoutError.unknown(debugDescription: "MockCheckoutSessionWalletUpdater has no session configured")
        }
        let session: CheckoutController.Session
        if suspendsFirstUpdate && !didSuspend {
            didSuspend = true
            session = try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        } else {
            session = sessionToReturn
        }
        currentTaxRegion = address
        return session
    }

    func resume() {
        guard let sessionToReturn else {
            continuation?.resume(throwing: CheckoutError.unknown(debugDescription: "MockCheckoutSessionWalletUpdater has no session configured"))
            continuation = nil
            return
        }
        continuation?.resume(returning: sessionToReturn)
        continuation = nil
    }
}

extension CheckoutController.ApplePayConfirmationParameters {
    static func makeMock(
        apiClient: STPAPIClient,
        returnURL: String = "stripe-ios-test://checkout-return",
        merchantDisplayName: String = "Test Merchant",
        applePayConfiguration: CheckoutApplePayConfiguration = PaymentElement.Configuration.ApplePayConfiguration(merchantId: "merchant.com.test"),
        shippingAddressRequired: Bool = false,
        defaultBillingDetails: CheckoutController.Configuration.Defaults.BillingDetails? = nil,
        presentationWindow: UIWindow? = nil,
        confirmationHandler: @escaping CheckoutController.ApplePayConfirmationParameters.ConfirmationHandler = { _ in
            .failed(CheckoutError.unknown(debugDescription: "Unexpected Apple Pay confirmation in test."))
        }
    ) -> CheckoutController.ApplePayConfirmationParameters {
        CheckoutController.ApplePayConfirmationParameters(
            applePayConfiguration: applePayConfiguration,
            apiClient: apiClient,
            returnURL: returnURL,
            merchantDisplayName: merchantDisplayName,
            shippingAddressRequired: shippingAddressRequired,
            defaultBillingDetails: defaultBillingDetails,
            presentationWindow: presentationWindow,
            confirmationHandler: confirmationHandler
        )
    }
}

// MARK: - PaymentPagesAPIResponse decorator helpers

extension PaymentPagesAPIResponse {
    func withCustomer(id: String = "cus_123") -> PaymentPagesAPIResponse {
        withOverrides(["customer": ["id": id]])
    }

    func withSessionId(_ id: String) -> PaymentPagesAPIResponse {
        withOverrides(["session_id": id])
    }

    private func withOverrides(_ overrides: [String: Any]) -> PaymentPagesAPIResponse {
        let json = (allResponseFields as? [String: Any] ?? [:])
            .merging(overrides) { _, new in new }
        return try! PaymentPagesAPIResponse.decode(fromAPIResponse: json)
    }
}
