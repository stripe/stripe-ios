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

    static func makeSessionJSON(_ overrides: [String: Any] = [:]) -> [String: Any] {
        baseSessionJSON.merging(overrides) { _, new in new }
    }

    // MARK: - Checkout-flow helpers

    /// Builds a `CheckoutController.Configuration`, replacing its `apiClient` with one that uses test stubs.
    ///
    /// - Parameters:
    ///   - apiResponse: The Checkout Session response returned by the stubbed `/init` request.
    ///   - configuration: An optional base configuration for test-specific settings.
    ///   - stubAllOutgoingRequests: Whether to stub every outgoing API request made by the client, or only the initialization request.
    @MainActor
    static func makeConfiguration(
        apiResponse: PaymentPagesAPIResponse = makeOpenSession(),
        configuration: CheckoutController.Configuration? = nil,
        stubAllOutgoingRequests: Bool = true
    ) -> CheckoutController.Configuration {
        // Use the production Checkout initializer with a test-controlled API client.
        let clientSecret = configuration?.clientSecret ?? "\(apiResponse.sessionId)_secret_abc"
        var resolvedConfiguration = configuration ?? CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        resolvedConfiguration.apiClient = makeStubbedAPIClient(
            apiResponse: apiResponse,
            clientSecret: clientSecret,
            stubAllOutgoingRequests: stubAllOutgoingRequests
        )
        return resolvedConfiguration
    }

    /// Builds a stubbed Checkout configuration that opts into Adaptive Pricing.
    @MainActor
    static func makeCurrencySelectorConfiguration(
        apiResponse: PaymentPagesAPIResponse = makeOpenSession(),
        configuration: CheckoutController.Configuration? = nil
    ) -> CheckoutController.Configuration {
        let clientSecret = configuration?.clientSecret ?? "\(apiResponse.sessionId)_secret_abc"
        var resolvedConfiguration = configuration ?? CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        resolvedConfiguration.adaptivePricing.allowed = true
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
                && request.url?.path == "/v1/payment_pages/\(sessionId)/init"
        }) { _ in
            // Feed CheckoutController(configuration:) the session fixture this test requested.
            var responseJSON = jsonObject(apiResponse.allResponseFields) as? [String: Any] ?? [:]
            responseJSON["session_id"] = responseJSON["session_id"] ?? sessionId
            let data = try! JSONSerialization.data(withJSONObject: responseJSON, options: [])
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
        // Init can trigger a session update (e.g. billing address tax sync); just echo the session back.
        stub(condition: { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/payment_pages/\(sessionId)"
        }) { _ in
            var responseJSON = jsonObject(apiResponse.allResponseFields) as? [String: Any] ?? [:]
            responseJSON["session_id"] = responseJSON["session_id"] ?? sessionId
            let data = try! JSONSerialization.data(withJSONObject: responseJSON, options: [])
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
            request.url?.path == "/v1/payment_pages/\(sessionId)/init"
        } response: { request in
            requestRecorder.append(
                .init(
                    kind: .initSession,
                    params: RequestBodyTestHelpers.formEncodedBodyParams(from: request)
                )
            )
            return HTTPStubsResponse(jsonObject: sessionJSON(), statusCode: initStatusCode, headers: nil)
        }

        stub { request in
            request.url?.path == "/v1/payment_pages/\(sessionId)"
        } response: { request in
            requestRecorder.append(
                .init(
                    kind: .updateSession,
                    params: RequestBodyTestHelpers.formEncodedBodyParams(from: request)
                )
            )
            let updateRequestNumber = requestRecorder.requests.filter { $0.kind == .updateSession }.count
            return HTTPStubsResponse(
                jsonObject: sessionJSON(),
                statusCode: updateStatusCode(updateRequestNumber),
                headers: nil
            )
        }
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
    override func present(completion: (@Sendable (Bool) -> Void)? = nil) {
        completion?(true)
    }

    override func dismiss(completion: (() -> Void)? = nil) {
        completion?()
    }
}

extension CheckoutController.ApplePayConfirmationParameters {
    static func makeMock(
        apiClient: STPAPIClient,
        returnURL: String = "stripe-ios-test://checkout-return",
        merchantDisplayName: String = "Test Merchant",
        applePayConfiguration: CheckoutController.ApplePayConfiguration = CheckoutController.ApplePayConfiguration(merchantId: "merchant.com.test"),
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
