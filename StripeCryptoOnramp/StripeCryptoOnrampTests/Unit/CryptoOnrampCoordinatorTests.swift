//
//  CryptoOnrampCoordinatorTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 7/20/26.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import PassKit
@_spi(STP) import StripeApplePay
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
@_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import UIKit
import XCTest

final class CryptoOnrampCoordinatorTests: APIStubbedTestCase {
    private var resolvedKey = "pk_test_platform_A"
    private var settingsRequests: [URLRequest] = []
    private var tokenRequests: [URLRequest] = []
    private var requestOrder: [String] = []
    private var settingsFailure: HTTPStubsResponse?
    private var tokenFailure: HTTPStubsResponse?
    private static let customerID = "crypto_customer_test"
    private static let settingsPath = "/v1/crypto/internal/platform_settings"
    private static let tokenPath = "/v1/crypto/internal/payment_token"

    override func tearDown() {
        LinkAccountContext.shared.account = nil
        super.tearDown()
    }

    func testCreateSucceedsWithoutSpecifyingPaymentMethodTypes() async throws {
        stub { request in
            request.url?.path == "/v1/elements/sessions"
        } response: { request in
            // Tests for a regression that occurred when `LinkController` briefly was passing
            // "link" for `payment_method_types`, ultimately triggering a failure to initialize onramp.
            XCTAssertFalse(request.url?.absoluteString.contains("payment_method_types") ?? true)
            return HTTPStubsResponse(jsonObject: Self.linkElementsSession, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_1234"

        let coordinator = try await CryptoOnrampCoordinator.create(apiClient: apiClient)
        XCTAssertNotNil(coordinator)
    }

    @MainActor
    func testPreAuthSameMerchantUsesOriginalPaymentMethodWithoutHint() async throws {
        try await assertMatchingMerchant(countryHint: nil)
    }

    @MainActor
    func testPreAuthSameMerchantPreservesCountryHint() async throws {
        try await assertMatchingMerchant(countryHint: "GB")
    }

    @MainActor
    private func assertMatchingMerchant(countryHint: String?) async throws {
        // Given an Apple Pay selection collected before authentication
        let coordinator = try await makeCoordinator(countryHint: countryHint)
        try await collectApplePay(coordinator, paymentMethodID: "pm_original")
        XCTAssertNil(queryParameters(settingsRequests[0])["crypto_customer_id"])
        XCTAssertEqual(queryParameters(settingsRequests[0])["country_hint"], countryHint)
        await coordinator.setCryptoCustomerId(Self.customerID)

        // When the authenticated merchant matches, every token attempt still resolves settings
        for _ in 0..<2 {
            let token = try await coordinator.createCryptoPaymentToken()
            XCTAssertEqual(token, "cpt_test")
        }

        // Then each token POST follows a fresh GET and retains the original selection and parameters
        XCTAssertEqual(requestOrder, ["settings", "settings", "token", "settings", "token"])
        for request in settingsRequests.dropFirst() {
            XCTAssertEqual(queryParameters(request), settingsParameters(countryHint: countryHint))
        }
        for request in tokenRequests {
            var expected = settingsParameters(countryHint: countryHint)
            expected["payment_method"] = "pm_original"
            XCTAssertEqual(bodyParameters(request), expected)
        }
    }

    @MainActor
    func testMerchantMismatchBlocksTokenAndCachesPersistedRegionKeyDespiteHint() async throws {
        // Given a hint that disagrees with the backend's persisted customer region
        let coordinator = try await makeCoordinator(countryHint: "US")
        try await collectApplePay(coordinator)
        await coordinator.setCryptoCustomerId(Self.customerID)
        resolvedKey = "pk_test_platform_B"

        // When the backend resolves a different key, repeated attempts remain blocked
        try await assertMerchantChanged(coordinator)
        try await assertMerchantChanged(coordinator)
        XCTAssertEqual(settingsRequests.count, 3)
        XCTAssertTrue(tokenRequests.isEmpty)
        XCTAssertEqual(queryParameters(settingsRequests[2]), settingsParameters(countryHint: "US"))

        // Then recollection uses the freshly cached client without another settings request
        let context = try await beginApplePay(coordinator)
        XCTAssertEqual(context.apiClient.publishableKey, resolvedKey)
        XCTAssertEqual(settingsRequests.count, 3)
        coordinator.applePayContext(context, didCompleteWith: .userCancellation, error: nil)
    }

    @MainActor
    func testLaterKYCChangeBypassesPreviouslyMatchingCachedSettings() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        await coordinator.setCryptoCustomerId(Self.customerID)
        _ = try await coordinator.createCryptoPaymentToken()

        // When KYC changes the merchant without changing the customer ID
        resolvedKey = "pk_test_platform_B"
        try await assertMerchantChanged(coordinator)

        // Then the previous matching resolution cannot authorize another token
        XCTAssertEqual(requestOrder, ["settings", "settings", "token", "settings"])
        XCTAssertEqual(tokenRequests.count, 1)
        XCTAssertEqual(queryParameters(settingsRequests[2])["crypto_customer_id"], Self.customerID)
    }

    @MainActor
    func testPreAuthSelectionWithoutCustomerDoesNotResolveOrSubmitToken() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        do {
            _ = try await coordinator.createCryptoPaymentToken()
            XCTFail("Expected missing customer ID")
        } catch {
            guard case CryptoOnrampCoordinator.Error.missingCryptoCustomerID = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(settingsRequests.count, 1)
        XCTAssertTrue(tokenRequests.isEmpty)
    }

    @MainActor
    func testSettingsNetworkFailureDoesNotFallBackToMatchingCache() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        await coordinator.setCryptoCustomerId(Self.customerID)
        _ = try await coordinator.createCryptoPaymentToken()
        settingsFailure = HTTPStubsResponse(error: NSError(domain: "SettingsNetworkFailure", code: 42))

        do {
            _ = try await coordinator.createCryptoPaymentToken()
            XCTFail("Expected settings failure")
        } catch {
            XCTAssertEqual((error as NSError).domain, "SettingsNetworkFailure")
        }
        XCTAssertEqual(settingsRequests.count, 3)
        XCTAssertEqual(tokenRequests.count, 1)
    }

    @MainActor
    func testSettingsAPIFailurePreservesErrorMappingAndDoesNotSubmitToken() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        await coordinator.setCryptoCustomerId(Self.customerID)
        settingsFailure = apiFailure(code: "crypto_onramp_transactions_unavailable_in_country")

        do {
            _ = try await coordinator.createCryptoPaymentToken()
            XCTFail("Expected settings failure")
        } catch {
            let mappedError = try XCTUnwrap(error as? UncategorizedError)
            XCTAssertEqual(mappedError.code, "crypto_onramp_transactions_unavailable_in_country")
            XCTAssertEqual(mappedError.requestID, "req_test")
        }
        XCTAssertEqual(settingsRequests.count, 2)
        XCTAssertTrue(tokenRequests.isEmpty)
    }

    @MainActor
    func testSuccessfulRecollectionReplacesOldSelectionOnlyOnCompletion() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator, paymentMethodID: "pm_original")
        await coordinator.setCryptoCustomerId(Self.customerID)
        resolvedKey = "pk_test_platform_B"
        try await assertMerchantChanged(coordinator)

        let context = try await beginApplePay(coordinator)
        XCTAssertEqual(context.apiClient.publishableKey, resolvedKey)
        try await stagePaymentMethod("pm_recollected", coordinator: coordinator, context: context)
        try await assertMerchantChanged(coordinator)
        XCTAssertTrue(tokenRequests.isEmpty)

        // When Apple Pay reports final success, the new selection becomes usable
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
        let settingsCount = settingsRequests.count
        _ = try await coordinator.createCryptoPaymentToken()
        XCTAssertEqual(settingsRequests.count, settingsCount)
        XCTAssertEqual(bodyParameters(try XCTUnwrap(tokenRequests.last))["payment_method"], "pm_recollected")
    }

    @MainActor
    func testCanceledAndFailedRecollectionKeepOriginalProvenance() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator, paymentMethodID: "pm_original")
        await coordinator.setCryptoCustomerId(Self.customerID)
        resolvedKey = "pk_test_platform_B"
        try await assertMerchantChanged(coordinator)

        for status in [STPApplePayContext.PaymentStatus.userCancellation, .error] {
            let context = try await beginApplePay(coordinator)
            try await stagePaymentMethod("pm_discarded", coordinator: coordinator, context: context)
            coordinator.applePayContext(context, didCompleteWith: status, error: nil)
            // A late success must not commit a canceled/failed attempt.
            coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
            try await assertMerchantChanged(coordinator)
        }
        XCTAssertTrue(tokenRequests.isEmpty)

        // The original selection, including its original key, survives both attempts.
        resolvedKey = "pk_test_platform_A"
        _ = try await coordinator.createCryptoPaymentToken()
        XCTAssertEqual(bodyParameters(try XCTUnwrap(tokenRequests.last))["payment_method"], "pm_original")
    }

    @MainActor
    func testAuthenticationBeforePaymentMethodCallbackPreservesAttemptProvenance() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        let context = try await beginApplePay(coordinator)

        // When authentication clears the cache and token validation replaces it while Apple Pay collects
        await coordinator.setCryptoCustomerId(Self.customerID)
        resolvedKey = "pk_test_platform_B"
        try await assertMerchantChanged(coordinator)
        XCTAssertEqual(context.apiClient.publishableKey, "pk_test_platform_A")
        try await stagePaymentMethod("pm_pre_auth", coordinator: coordinator, context: context)
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)

        // Then the callback uses the context's key and retains the attempt's pre-auth requirement
        try await assertMerchantChanged(coordinator)
        XCTAssertEqual(settingsRequests.count, 3)
        XCTAssertTrue(tokenRequests.isEmpty)
    }

    @MainActor
    func testPaymentMethodCallbackCapturesKeyFromItsContext() async throws {
        let coordinator = try await makeCoordinator()
        let context = try await beginApplePay(coordinator)
        await coordinator.setCryptoCustomerId(Self.customerID)

        // Given the context's client at payment-method creation differs from its initial client
        resolvedKey = "pk_test_platform_B"
        context.apiClient = STPAPIClient(publishableKey: resolvedKey)
        try await stagePaymentMethod("pm_callback_context", coordinator: coordinator, context: context)

        // When the client changes after the callback, the staged source retains the captured key
        context.apiClient = STPAPIClient(publishableKey: "pk_test_platform_C")
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
        _ = try await coordinator.createCryptoPaymentToken()

        // Then validation matches the callback's key and submits its original payment method
        XCTAssertEqual(requestOrder, ["settings", "settings", "token"])
        XCTAssertEqual(bodyParameters(try XCTUnwrap(tokenRequests.last))["payment_method"], "pm_callback_context")
    }

    @MainActor
    func testTokenAuthenticationInvalidatesCacheAndPreservesPreAuthSelection() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        let authAPIClient = stubbedAPIClient()
        authAPIClient.publishableKey = "pk_test_auth"
        let attestService = MockAppAttestService()
        await attestService.setShouldFailKeygenWithError(NSError(domain: "TestAttestation", code: 1))
        let originalAttest = STPAPIClient.shared.stripeAttest
        // Link's auth-token lookup uses the shared client. Isolate its attestation from the device.
        STPAPIClient.shared.stripeAttest = StripeAttest(
            appAttestService: attestService,
            appAttestBackend: MockAttestBackend(),
            apiClient: authAPIClient
        )
        defer { STPAPIClient.shared.stripeAttest = originalAttest }
        var authenticationRequests = 0
        stub { $0.url?.path == "/v1/consumers/mobile/sessions/lookup" } response: { [self] request in
            authenticationRequests += 1
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(bodyParameters(request)["link_auth_token_client_secret"], "auth_token_test")
            return HTTPStubsResponse(jsonObject: [
                "exists": true,
                "publishable_key": "pk_test_link",
                "consumer_session": [
                    "client_secret": "consumer_secret_test",
                    "email_address": "test@example.com",
                    "redacted_formatted_phone_number": "***1234",
                    "verification_sessions": [["type": "LINK_AUTH_TOKEN", "state": "VERIFIED"]],
                ],
            ], statusCode: 200, headers: nil)
        }
        stub { $0.url?.path == "/v1/crypto/internal/customers" } response: { [self] request in
            authenticationRequests += 1
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(bodyParameters(request)["credentials[consumer_session_client_secret]"], "consumer_secret_test")
            return HTTPStubsResponse(jsonObject: ["id": Self.customerID], statusCode: 200, headers: nil)
        }

        // When the public no-UI authentication path completes
        try await coordinator.authenticateUserWithToken("auth_token_test")
        XCTAssertEqual(authenticationRequests, 2)
        resolvedKey = "pk_test_platform_B"

        // Then a new collection resolves B, demonstrating that authentication cleared cached A
        let context = try await beginApplePay(coordinator)
        XCTAssertEqual(context.apiClient.publishableKey, resolvedKey)
        XCTAssertEqual(settingsRequests.count, 2)
        XCTAssertEqual(queryParameters(settingsRequests[1])["crypto_customer_id"], Self.customerID)
        coordinator.applePayContext(context, didCompleteWith: .userCancellation, error: nil)
        try await assertMerchantChanged(coordinator)
        XCTAssertEqual(settingsRequests.count, 3)
        XCTAssertTrue(tokenRequests.isEmpty)
    }

    @MainActor
    func testFailedAttemptPreparationClearsMetadataAndPreservesSelection() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        await coordinator.setCryptoCustomerId(Self.customerID)
        settingsFailure = apiFailure(code: "settings_unavailable")
        let context = try makeApplePayContext(coordinator)
        do {
            try await coordinator.prepareApplePayContext(context)
            XCTFail("Expected preparation failure")
        } catch {
            XCTAssertTrue(error is StripeError)
        }
        do {
            try await stagePaymentMethod("pm_failed", coordinator: coordinator, context: context)
            XCTFail("Expected missing provenance")
        } catch {
            XCTAssertTrue(error is ApplePayPaymentStatus.Error)
        }
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
        settingsFailure = nil
        resolvedKey = "pk_test_platform_B"
        try await assertMerchantChanged(coordinator)
        XCTAssertTrue(tokenRequests.isEmpty)
    }

    @MainActor
    func testAuthFirstApplePayDoesNotForceMerchantRevalidation() async throws {
        let coordinator = try await makeCoordinator(cryptoCustomerID: Self.customerID)
        try await collectApplePay(coordinator)
        resolvedKey = "pk_test_platform_B"
        _ = try await coordinator.createCryptoPaymentToken()
        _ = try await coordinator.createCryptoPaymentToken()
        XCTAssertEqual(settingsRequests.count, 1)
        XCTAssertEqual(tokenRequests.count, 2)
    }

    @MainActor
    func testBackendPaymentMethodFailureIsNotReclassifiedAsMerchantChange() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        await coordinator.setCryptoCustomerId(Self.customerID)
        tokenFailure = apiFailure(code: "resource_missing", param: "payment_method")
        do {
            _ = try await coordinator.createCryptoPaymentToken()
            XCTFail("Expected token failure")
        } catch {
            XCTAssertEqual((error as? UncategorizedError)?.code, "resource_missing")
            XCTAssertFalse(error is PaymentMethodMerchantChangedError)
        }
        XCTAssertEqual(tokenRequests.count, 1)
    }

    @MainActor
    func testMissingOrWrongContextProvenanceFailsCollection() async throws {
        let coordinator = try await makeCoordinator()
        let context = try makeApplePayContext(coordinator)
        do {
            try await stagePaymentMethod("pm_untracked", coordinator: coordinator, context: context)
            XCTFail("Expected missing provenance to fail")
        } catch {
            XCTAssertTrue(error is ApplePayPaymentStatus.Error)
        }
        let activeContext = try await beginApplePay(coordinator)
        try await stagePaymentMethod("pm_active", coordinator: coordinator, context: activeContext)
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
        await assertNoSelection(coordinator)
        coordinator.applePayContext(activeContext, didCompleteWith: .success, error: nil)
        await coordinator.setCryptoCustomerId(Self.customerID)
        _ = try await coordinator.createCryptoPaymentToken()
        XCTAssertEqual(bodyParameters(try XCTUnwrap(tokenRequests.last))["payment_method"], "pm_active")
    }

    @MainActor
    func testLogoutClearsCommittedPendingAndAttemptState() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        let context = try await beginApplePay(coordinator)
        try await stagePaymentMethod("pm_pending", coordinator: coordinator, context: context)

        try await coordinator.logOut()
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
        await assertNoSelection(coordinator)
        do {
            try await stagePaymentMethod("pm_late", coordinator: coordinator, context: context)
            XCTFail("Expected attempt metadata to be cleared")
        } catch {
            XCTAssertTrue(error is ApplePayPaymentStatus.Error)
        }
        resolvedKey = "pk_test_platform_B"
        let newContext = try await beginApplePay(coordinator)
        XCTAssertEqual(newContext.apiClient.publishableKey, resolvedKey)
        XCTAssertEqual(settingsRequests.count, 2)
        XCTAssertTrue(tokenRequests.isEmpty)
        coordinator.applePayContext(newContext, didCompleteWith: .userCancellation, error: nil)
    }

    @MainActor
    func testLinkCollectionStillRequiresAuthenticationBeforeAnyPlatformLookup() async throws {
        let coordinator = try await makeCoordinator()
        for type in [PaymentMethodType.card, .bankAccount, .cardAndBankAccount] {
            do {
                _ = try await coordinator.collectPaymentMethod(type: type, from: UIViewController())
                XCTFail("Expected missing Link consumer")
            } catch {
                guard case LinkController.IntegrationError.noActiveLinkConsumer = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
        }
        await assertNoSelection(coordinator)
        XCTAssertTrue(settingsRequests.isEmpty)
        XCTAssertTrue(tokenRequests.isEmpty)
    }

    @MainActor
    private func makeCoordinator(cryptoCustomerID: String? = nil, countryHint: String? = nil) async throws -> CryptoOnrampCoordinator {
        LinkAccountContext.shared.account = nil
        stub { $0.url?.path == "/v1/elements/sessions" } response: { _ in
            HTTPStubsResponse(jsonObject: Self.linkElementsSession, statusCode: 200, headers: nil)
        }
        stub { $0.url?.path == Self.settingsPath } response: { [self] request in
            XCTAssertEqual(request.httpMethod, "GET")
            settingsRequests.append(request)
            requestOrder.append("settings")
            return settingsFailure ?? HTTPStubsResponse(jsonObject: ["publishable_key": resolvedKey], statusCode: 200, headers: nil)
        }
        stub { $0.url?.path == Self.tokenPath } response: { [self] request in
            XCTAssertEqual(request.httpMethod, "POST")
            tokenRequests.append(request)
            requestOrder.append("token")
            return tokenFailure ?? HTTPStubsResponse(jsonObject: ["id": "cpt_test"], statusCode: 200, headers: nil)
        }
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_partner"
        return try await CryptoOnrampCoordinator.create(apiClient: apiClient, cryptoCustomerID: cryptoCustomerID, countryHint: countryHint)
    }

    @MainActor
    private func makeApplePayContext(_ coordinator: CryptoOnrampCoordinator) throws -> STPApplePayContext {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.stripe.test"
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.supportedNetworks = [.visa]
        request.merchantCapabilities = [.capability3DS]
        request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Crypto", amount: 10)]
        return try XCTUnwrap(STPApplePayContext(paymentRequest: request, delegate: coordinator))
    }

    @MainActor
    private func beginApplePay(_ coordinator: CryptoOnrampCoordinator) async throws -> STPApplePayContext {
        let context = try makeApplePayContext(coordinator)
        try await coordinator.prepareApplePayContext(context)
        return context
    }

    @MainActor
    private func stagePaymentMethod(_ id: String, coordinator: CryptoOnrampCoordinator, context: STPApplePayContext) async throws {
        let data = try JSONSerialization.data(withJSONObject: ["id": id, "created": 0, "livemode": false, "type": "card"])
        let paymentMethod: StripeAPI.PaymentMethod = try StripeJSONDecoder.decode(jsonData: data)
        let result = try await coordinator.applePayContext(context, didCreatePaymentMethod: paymentMethod, paymentInformation: PKPayment())
        XCTAssertEqual(result, STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT)
    }

    @MainActor
    private func collectApplePay(_ coordinator: CryptoOnrampCoordinator, paymentMethodID: String = "pm_original") async throws {
        let context = try await beginApplePay(coordinator)
        try await stagePaymentMethod(paymentMethodID, coordinator: coordinator, context: context)
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
    }

    private func assertMerchantChanged(_ coordinator: CryptoOnrampCoordinator, file: StaticString = #filePath, line: UInt = #line) async throws {
        let tokenCount = tokenRequests.count
        do {
            _ = try await coordinator.createCryptoPaymentToken()
            XCTFail("Expected merchant change", file: file, line: line)
        } catch {
            XCTAssertTrue(error is PaymentMethodMerchantChangedError, "Unexpected error: \(error)", file: file, line: line)
        }
        XCTAssertEqual(tokenRequests.count, tokenCount, file: file, line: line)
    }

    private func assertNoSelection(_ coordinator: CryptoOnrampCoordinator) async {
        do {
            _ = try await coordinator.createCryptoPaymentToken()
            XCTFail("Expected no selection")
        } catch {
            guard case CryptoOnrampCoordinator.Error.invalidSelectedPaymentSource = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    private func queryParameters(_ request: URLRequest) -> [String: String] {
        return parameters(request.url?.query)
    }

    private func bodyParameters(_ request: URLRequest) -> [String: String] {
        return parameters(request.ohhttpStubs_httpBody.flatMap { String(data: $0, encoding: .utf8) })
    }

    private func parameters(_ encodedParameters: String?) -> [String: String] {
        return (encodedParameters ?? "").split(separator: "&").reduce(into: [:]) { result, pair in
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let key = String(parts[0]).removingPercentEncoding,
                  let value = String(parts[1]).removingPercentEncoding else {
                return
            }
            result[key] = value
        }
    }

    private func settingsParameters(countryHint: String?) -> [String: String] {
        var parameters = ["crypto_customer_id": Self.customerID, "ui_mode": "headless"]
        parameters["country_hint"] = countryHint
        return parameters
    }

    private func apiFailure(code: String, param: String? = nil) -> HTTPStubsResponse {
        var error = ["type": "invalid_request_error", "code": code, "message": "Request failed."]
        error["param"] = param
        return HTTPStubsResponse(jsonObject: ["error": error], statusCode: 400, headers: ["Request-Id": "req_test"])
    }

    private static let linkElementsSession: [String: Any] = [
        "config_id": "config_crypto_onramp",
        "link_settings": [
            "link_funding_sources": ["CARD"],
            "link_mobile_use_attestation_endpoints": true,
        ],
        "merchant_country": "US",
        "ordered_payment_method_types_and_wallets": ["card"],
        "payment_method_preference": [
            "country_code": "US",
            "object": "payment_method_preference",
            "ordered_payment_method_types": ["card"],
            "type": "deferred_intent",
        ],
        "session_id": "elements_session_crypto_onramp",
    ]
}
