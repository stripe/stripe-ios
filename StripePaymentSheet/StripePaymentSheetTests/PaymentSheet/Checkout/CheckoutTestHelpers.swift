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
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

extension Checkout.Amount {
    /// Test helper for constructing a ``Checkout/Amount`` from a minor-units integer.
    static func testValue(_ minorUnits: Int, currency: String = "usd") -> Checkout.Amount {
        return PaymentPagesAPIResponse.makeAmount(minorUnits, currency: currency)
    }
}

// MARK: - Shared Mock Delegates

@MainActor
class MockCheckoutDelegate: CheckoutDelegate {
    var lastSession: Checkout.Session?
    var updateSessionCallCount = 0
    var beginLoadingCallCount = 0
    var finishLoadingCallCount = 0
    var onUpdateSession: (() -> Void)?

    func checkoutDidBeginLoading(_ checkout: Checkout) {
        beginLoadingCallCount += 1
    }

    func checkoutDidFinishLoading(_ checkout: Checkout) {
        finishLoadingCallCount += 1
    }

    func checkoutDidUpdateSession(_ checkout: Checkout, session: Checkout.Session) {
        updateSessionCallCount += 1
        lastSession = session
        onUpdateSession?()
    }
}

// MARK: - Emission Recorder

@MainActor
class CheckoutEmissionRecorder {
    var sessions: [Checkout.Session] = []
    var loading: [Bool] = []
    private var subscriptions = Set<AnyCancellable>()

    init(_ checkout: Checkout) {
        checkout.$session.dropFirst().sink { [weak self] in self?.sessions.append($0) }
            .store(in: &subscriptions)
        checkout.$isLoading.dropFirst().sink { [weak self] in self?.loading.append($0) }
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

    static let baseSessionJSON: [String: Any] = [
        "session_id": "cs_test",
        "object": "checkout.session",
        "livemode": false,
        "mode": "payment",
        "payment_status": "unpaid",
        "payment_method_types": ["card"],
        "elements_session": minimalElementsSessionJSON,
    ]

    /// Creates a `PaymentPagesAPIResponse` from `baseSessionJSON` with top-level key overrides.
    /// To test field *absence*, mutate `baseSessionJSON` directly instead.
    static func makeSession(_ overrides: [String: Any] = [:]) -> PaymentPagesAPIResponse {
        let json = makeSessionJSON(overrides)
        guard let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json) else {
            fatalError("makeSession: failed to decode PaymentPagesAPIResponse from \(json)")
        }
        return session
    }

    static func makeSessionJSON(_ overrides: [String: Any] = [:]) -> [String: Any] {
        baseSessionJSON.merging(overrides) { _, new in new }
    }

    // MARK: - Checkout-flow helpers

    /// Builds a `Checkout.Configuration`, replacing its `apiClient` with one that uses test stubs.
    ///
    /// - Parameters:
    ///   - apiResponse: The Checkout Session response returned by the stubbed `/init` request.
    ///   - configuration: An optional base configuration for test-specific settings.
    ///   - stubAllOutgoingRequests: Whether to stub every outgoing API request made by the client, or only the initialization request.
    @MainActor
    static func makeConfiguration(
        apiResponse: PaymentPagesAPIResponse = makeOpenSession(),
        configuration: Checkout.Configuration? = nil,
        stubAllOutgoingRequests: Bool = true
    ) -> Checkout.Configuration {
        // Use the production Checkout initializer with a test-controlled API client.
        let clientSecret = configuration?.clientSecret ?? apiResponse.clientSecret ?? "cs_test_123_secret_abc"
        var resolvedConfiguration = configuration ?? Checkout.Configuration(clientSecret: clientSecret)
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
        configuration: Checkout.Configuration? = nil
    ) -> Checkout.Configuration {
        let clientSecret = configuration?.clientSecret ?? apiResponse.clientSecret ?? "cs_test_123_secret_abc"
        var resolvedConfiguration = configuration ?? Checkout.Configuration(clientSecret: clientSecret)
        resolvedConfiguration.adaptivePricing.allowed = true
        return makeConfiguration(apiResponse: apiResponse, configuration: resolvedConfiguration)
    }

    @MainActor
    static func makeStubbedAPIClient(
        apiResponse: PaymentPagesAPIResponse = makeOpenSession(),
        clientSecret: String? = nil,
        stubAllOutgoingRequests: Bool = true
    ) -> STPAPIClient {
        let resolvedClientSecret = clientSecret ?? apiResponse.clientSecret ?? "cs_test_123_secret_abc"
        let sessionId = Checkout.extractSessionId(from: resolvedClientSecret)
        let apiClient = APIStubbedTestCase.stubbedAPIClient()

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
            // Feed Checkout(configuration:) the session fixture this test requested.
            var responseJSON = jsonObject(apiResponse.allResponseFields) as? [String: Any] ?? [:]
            responseJSON["client_secret"] = resolvedClientSecret
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
    /// _ = try await Checkout(configuration: configuration)
    /// XCTAssertEqual(recorder.requests.map(\.kind), [.initSession, .updateSession])
    /// XCTAssertEqual(recorder.requests[1].params["tax_region[country]"], "US")
    /// ```
    static func stubCheckoutSessionRequests(
        sessionId: String,
        requestRecorder: CheckoutSessionRequestRecorder,
        sessionJSON: @escaping () -> [AnyHashable: Any],
        initStatusCode: Int32 = 200,
        updateStatusCode: Int32 = 200
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
            return HTTPStubsResponse(jsonObject: sessionJSON(), statusCode: updateStatusCode, headers: nil)
        }
    }

    static let openSessionJSON: [AnyHashable: Any] = [
        "session_id": "cs_test_123",
        "object": "checkout.session",
        "client_secret": "cs_test_123_secret_abc",
        "livemode": false,
        "mode": "payment",
        "status": "open",
        "payment_status": "unpaid",
        "payment_method_types": ["card"],
        "currency": "usd",
        "elements_session": minimalElementsSessionJSON,
    ]

    static func makeOpenSession(customerEmail: String? = nil, billingAddressCollection: String? = nil) -> PaymentPagesAPIResponse {
        var json = openSessionJSON
        json["customer_email"] = customerEmail
        json["billing_address_collection"] = billingAddressCollection
        return PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
    }

    static func makeClosedSession() -> PaymentPagesAPIResponse {
        var json = openSessionJSON
        json["status"] = "complete"
        json["payment_status"] = "paid"
        return PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
    }

    static func makeOpenSession(allowedCountries: [String]) -> PaymentPagesAPIResponse {
        var json = openSessionJSON
        json["shipping_address_collection"] = ["allowed_countries": allowedCountries]
        return PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
    }

    static func makeAdaptivePricingSession(
        currency: String = "usd",
        adaptivePricingActive: Bool = true,
        includeLocalizedPrices: Bool = true,
        includeExchangeRateFields: Bool = true,
        integrationAmount: Int = 1200,
        localAmount: Int = 1000
    ) -> PaymentPagesAPIResponse {
        var json: [AnyHashable: Any] = openSessionJSON
        json["currency"] = currency
        json["total_summary"] = [
            "subtotal": integrationAmount,
            "total": integrationAmount,
            "due": integrationAmount,
        ]
        json["developer_tool_context"] = [
            "adaptive_pricing": [
                "active": adaptivePricingActive,
            ],
        ]

        if includeLocalizedPrices {
            var localCurrencyOption: [AnyHashable: Any] = [
                "currency": "gbp",
                "amount": localAmount,
            ]
            if includeExchangeRateFields {
                localCurrencyOption["presentment_exchange_rate"] = "0.776917"
                localCurrencyOption["conversion_markup_bps"] = 400
            }
            json["adaptive_pricing_info"] = [
                "integration_currency": "usd",
                "integration_amount": integrationAmount,
                "active_presentment_currency": currency,
                "local_currency_options": [localCurrencyOption],
            ]
        }

        return PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
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
        return PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
    }
}
