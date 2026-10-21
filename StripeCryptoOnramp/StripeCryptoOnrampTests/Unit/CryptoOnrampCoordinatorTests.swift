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
@testable @_spi(STP) @_spi(CryptoOnrampAlpha) import StripePaymentSheet
import UIKit
import XCTest

final class CryptoOnrampCoordinatorTests: APIStubbedTestCase {
    private var resolvedKey = "pk_test_platform_A"
    private var settingsRequests: [URLRequest] = []
    private var tokenRequests: [URLRequest] = []
    private var requestOrder: [String] = []
    private var settingsFailure: HTTPStubsResponse?
    private var tokenFailure: HTTPStubsResponse?
    private var onTokenRequest: (@MainActor () -> Void)?
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
        try await assertKYCRegionChanged(coordinator)
        try await assertKYCRegionChanged(coordinator)
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
        try await assertKYCRegionChanged(coordinator)

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
        try await assertKYCRegionChanged(coordinator)

        let context = try await beginApplePay(coordinator)
        XCTAssertEqual(context.apiClient.publishableKey, resolvedKey)
        try await stagePaymentMethod("pm_recollected", coordinator: coordinator, context: context)
        try await assertKYCRegionChanged(coordinator)
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
        try await assertKYCRegionChanged(coordinator)

        for status in [STPApplePayContext.PaymentStatus.userCancellation, .error] {
            let context = try await beginApplePay(coordinator)
            try await stagePaymentMethod("pm_discarded", coordinator: coordinator, context: context)
            coordinator.applePayContext(context, didCompleteWith: status, error: nil)
            // A late success must not commit a canceled/failed attempt.
            coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
            try await assertKYCRegionChanged(coordinator)
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
        try await assertKYCRegionChanged(coordinator)
        XCTAssertEqual(context.apiClient.publishableKey, "pk_test_platform_A")
        try await stagePaymentMethod("pm_pre_auth", coordinator: coordinator, context: context)
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)

        // Then the callback uses the context's key and retains the attempt's pre-auth requirement
        try await assertKYCRegionChanged(coordinator)
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
        try await assertKYCRegionChanged(coordinator)
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
        try await assertKYCRegionChanged(coordinator)
        XCTAssertTrue(tokenRequests.isEmpty)
    }

    @MainActor
    func testAuthFirstApplePayDoesNotForcePublishableKeyRevalidation() async throws {
        let coordinator = try await makeCoordinator(cryptoCustomerID: Self.customerID)
        try await collectApplePay(coordinator)
        resolvedKey = "pk_test_platform_B"
        _ = try await coordinator.createCryptoPaymentToken()
        _ = try await coordinator.createCryptoPaymentToken()
        XCTAssertEqual(settingsRequests.count, 1)
        XCTAssertEqual(tokenRequests.count, 2)
    }

    @MainActor
    func testBackendPaymentMethodFailureIsNotReclassifiedAsKYCRegionChange() async throws {
        let coordinator = try await makeCoordinator()
        try await collectApplePay(coordinator)
        await coordinator.setCryptoCustomerId(Self.customerID)
        tokenFailure = apiFailure(code: "resource_missing", param: "payment_method")
        do {
            _ = try await coordinator.createCryptoPaymentToken()
            XCTFail("Expected token failure")
        } catch {
            XCTAssertEqual((error as? UncategorizedError)?.code, "resource_missing")
            XCTAssertFalse(error is PaymentMethodKYCRegionChangedError)
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
    func testTokenDetailsMapFundingWithoutAdditionalRequests() async throws {
        let analytics = MockAnalyticsClientV2()
        let coordinator = try await makeCoordinator(cryptoCustomerID: Self.customerID, analyticsClient: analytics)
        let cases: [(String?, STPCardFundingType)] = [
            ("debit", .debit), ("credit", .credit), ("prepaid", .prepaid),
            ("unknown", .other), ("future_funding", .other), (nil, .other),
        ]
        for (index, testCase) in cases.enumerated() {
            let (funding, expectedFunding) = testCase
            try await collectApplePay(coordinator, card: cardFixture(funding: funding))

            let result = try await coordinator.createCryptoPaymentTokenWithDetails()

            XCTAssertEqual(result.cryptoPaymentToken, "cpt_test")
            let details = try XCTUnwrap(result.cardDetails)
            XCTAssertEqual(details.funding, expectedFunding)
            XCTAssertEqual(details.brand, .visa)
            XCTAssertEqual(details.last4, "4242")
            XCTAssertEqual(tokenRequests.count, index + 1)
            XCTAssertEqual(settingsRequests.count, 1)
            XCTAssertEqual(bodyParameters(try XCTUnwrap(tokenRequests.last))["payment_method"], "pm_original")
            XCTAssertEqual(analytics.loggedAnalyticPayloads(withEventName: "onramp.crypto_payment_token_created").count, index + 1)
        }
        for payload in analytics.loggedAnalyticsPayloads {
            XCTAssertNil(payload["card_details"])
            XCTAssertNil(payload["funding"])
            XCTAssertNil(payload["brand"])
            XCTAssertNil(payload["last4"])
        }
    }

    @MainActor
    func testTokenDetailsMapBrandsAndMissingCardFields() async throws {
        let coordinator = try await makeCoordinator(cryptoCustomerID: Self.customerID)
        let brands: [(String, STPCardBrand)] = [
            ("visa", .visa), ("amex", .amex), ("mastercard", .mastercard),
            ("discover", .discover), ("jcb", .JCB), ("diners", .dinersClub),
            ("unionpay", .unionPay), ("unknown", .unknown), ("future_brand", .unknown),
        ]
        for (brand, expectedBrand) in brands {
            try await collectApplePay(coordinator, card: cardFixture(brand: brand, last4: nil))
            let result = try await coordinator.createCryptoPaymentTokenWithDetails()
            let details = try XCTUnwrap(result.cardDetails)
            XCTAssertEqual(details.brand, expectedBrand)
            XCTAssertNil(details.last4)
        }
        try await collectApplePay(coordinator)
        let result = try await coordinator.createCryptoPaymentTokenWithDetails()
        XCTAssertEqual(result.cryptoPaymentToken, "cpt_test")
        XCTAssertNil(result.cardDetails)
    }

    func testLinkSelectionHasNoCardDetails() {
        XCTAssertNil(SelectedPaymentSource.link.cardDetails)
    }

    @MainActor
    func testDetailedAndLegacyTokensHaveSameRequestsAndSingleAnalyticsEvent() async throws {
        let analytics = MockAnalyticsClientV2()
        let coordinator = try await makeCoordinator(countryHint: "GB", analyticsClient: analytics)
        try await collectApplePay(coordinator, card: cardFixture())
        await coordinator.setCryptoCustomerId(Self.customerID)

        let legacyToken: String = try await coordinator.createCryptoPaymentToken()
        let result = try await coordinator.createCryptoPaymentTokenWithDetails()

        XCTAssertEqual(legacyToken, result.cryptoPaymentToken)
        XCTAssertEqual(result.cardDetails?.funding, .debit)
        XCTAssertEqual(requestOrder, ["settings", "settings", "token", "settings", "token"])
        XCTAssertEqual(bodyParameters(tokenRequests[0]), bodyParameters(tokenRequests[1]))
        XCTAssertEqual(queryParameters(settingsRequests[1]), settingsParameters(countryHint: "GB"))
        XCTAssertEqual(queryParameters(settingsRequests[1]), queryParameters(settingsRequests[2]))
        let events = analytics.loggedAnalyticPayloads(withEventName: "onramp.crypto_payment_token_created")
        XCTAssertEqual(events.count, 2)
        XCTAssertTrue(events.allSatisfy { $0["payment_method_type"] as? String == "apple_pay" })
    }

    @MainActor
    func testTokenDetailsFollowOnlySuccessfullyCommittedSelections() async throws {
        let coordinator = try await makeCoordinator(cryptoCustomerID: Self.customerID)
        try await collectApplePay(coordinator, card: cardFixture())

        for status in [STPApplePayContext.PaymentStatus.userCancellation, .error, .success] {
            let context = try await beginApplePay(coordinator)
            try await stagePaymentMethod(
                "pm_recollected", coordinator: coordinator, context: context,
                card: cardFixture(funding: "credit", brand: "mastercard", last4: "4444")
            )
            // A staged candidate must not replace the committed card, even during token creation.
            let pendingResult = try await coordinator.createCryptoPaymentTokenWithDetails()
            XCTAssertEqual(pendingResult.cardDetails?.funding, .debit)
            XCTAssertEqual(pendingResult.cardDetails?.last4, "4242")
            XCTAssertEqual(bodyParameters(try XCTUnwrap(tokenRequests.last))["payment_method"], "pm_original")

            coordinator.applePayContext(context, didCompleteWith: status, error: nil)
            // A late success cannot revive a discarded attempt.
            coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
            let result = try await coordinator.createCryptoPaymentTokenWithDetails()
            let succeeded = status == .success
            XCTAssertEqual(result.cryptoPaymentToken, "cpt_test")
            XCTAssertEqual(result.cardDetails?.funding, succeeded ? .credit : .debit)
            XCTAssertEqual(result.cardDetails?.brand, succeeded ? .mastercard : .visa)
            XCTAssertEqual(result.cardDetails?.last4, succeeded ? "4444" : "4242")
            XCTAssertEqual(bodyParameters(try XCTUnwrap(tokenRequests.last))["payment_method"], succeeded ? "pm_recollected" : "pm_original")
        }
        XCTAssertEqual(settingsRequests.count, 1)
    }

    @MainActor
    func testInFlightTokenKeepsCapturedCardDetailsWhenSelectionChanges() async throws {
        let coordinator = try await makeCoordinator(cryptoCustomerID: Self.customerID)
        try await collectApplePay(coordinator, card: cardFixture())
        let context = try await beginApplePay(coordinator)
        try await stagePaymentMethod(
            "pm_recollected", coordinator: coordinator, context: context,
            card: cardFixture(funding: "credit", brand: "mastercard", last4: "4444")
        )
        // Commit the new selection after the token POST arrives but before its response is delivered.
        onTokenRequest = {
            coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
        }
        let inFlightResult = try await coordinator.createCryptoPaymentTokenWithDetails()
        onTokenRequest = nil
        let nextResult = try await coordinator.createCryptoPaymentTokenWithDetails()

        XCTAssertEqual(inFlightResult.cryptoPaymentToken, "cpt_test")
        XCTAssertEqual(inFlightResult.cardDetails?.funding, .debit)
        XCTAssertEqual(inFlightResult.cardDetails?.brand, .visa)
        XCTAssertEqual(inFlightResult.cardDetails?.last4, "4242")
        XCTAssertEqual(nextResult.cardDetails?.funding, .credit)
        XCTAssertEqual(nextResult.cardDetails?.brand, .mastercard)
        XCTAssertEqual(nextResult.cardDetails?.last4, "4444")
        XCTAssertEqual(tokenRequests.map { bodyParameters($0)["payment_method"] }, ["pm_original", "pm_recollected"])
        XCTAssertEqual(settingsRequests.count, 1)
    }

    @MainActor
    func testBothTokenMethodsRejectDiscardedSelectionsAfterLogout() async throws {
        let coordinator = try await makeCoordinator(cryptoCustomerID: Self.customerID)
        try await collectApplePay(coordinator, card: cardFixture())
        let context = try await beginApplePay(coordinator)
        try await stagePaymentMethod("pm_pending", coordinator: coordinator, context: context, card: cardFixture(funding: "credit"))
        try await coordinator.logOut()
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
        do {
            try await stagePaymentMethod("pm_late", coordinator: coordinator, context: context, card: cardFixture())
            XCTFail("Expected discarded attempt to reject late metadata")
        } catch {
            XCTAssertTrue(error is ApplePayPaymentStatus.Error)
        }
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
        await assertBothTokenMethodsFail(coordinator) { error in
            guard case CryptoOnrampCoordinator.Error.invalidSelectedPaymentSource = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertTrue(tokenRequests.isEmpty)
    }

    @MainActor
    func testBothTokenMethodsPreserveValidationOrderAndErrorMapping() async throws {
        let analytics = MockAnalyticsClientV2()
        let coordinator = try await makeCoordinator(analyticsClient: analytics)
        await assertBothTokenMethodsFail(coordinator) { error in
            guard case CryptoOnrampCoordinator.Error.invalidSelectedPaymentSource = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertTrue(requestOrder.isEmpty)

        try await collectApplePay(coordinator, card: cardFixture())
        await assertBothTokenMethodsFail(coordinator) { error in
            guard case CryptoOnrampCoordinator.Error.missingCryptoCustomerID = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(requestOrder, ["settings"])

        await coordinator.setCryptoCustomerId(Self.customerID)
        resolvedKey = "pk_test_platform_B"
        await assertBothTokenMethodsFail(coordinator) { XCTAssertTrue($0 is PaymentMethodKYCRegionChangedError) }
        XCTAssertEqual(requestOrder, ["settings", "settings", "settings"])
        XCTAssertTrue(tokenRequests.isEmpty)

        resolvedKey = "pk_test_platform_A"
        _ = try await coordinator.createCryptoPaymentTokenWithDetails()
        settingsFailure = HTTPStubsResponse(error: NSError(domain: "SettingsNetworkFailure", code: 42))
        await assertBothTokenMethodsFail(coordinator) { XCTAssertEqual(($0 as NSError).domain, "SettingsNetworkFailure") }
        XCTAssertEqual(tokenRequests.count, 1)
        XCTAssertEqual(requestOrder, ["settings", "settings", "settings", "settings", "token", "settings", "settings"])

        settingsFailure = apiFailure(code: "settings_unavailable")
        await assertBothTokenMethodsFail(coordinator) {
            XCTAssertEqual(($0 as? UncategorizedError)?.code, "settings_unavailable")
            XCTAssertEqual(($0 as? UncategorizedError)?.requestID, "req_test")
        }
        XCTAssertEqual(tokenRequests.count, 1)

        settingsFailure = nil
        tokenFailure = HTTPStubsResponse(error: NSError(domain: "TokenNetworkFailure", code: 42))
        await assertBothTokenMethodsFail(coordinator) { XCTAssertEqual(($0 as NSError).domain, "TokenNetworkFailure") }
        tokenFailure = apiFailure(code: "resource_missing", param: "payment_method")
        await assertBothTokenMethodsFail(coordinator) {
            XCTAssertEqual(($0 as? UncategorizedError)?.code, "resource_missing")
            XCTAssertFalse($0 is PaymentMethodKYCRegionChangedError)
        }
        XCTAssertEqual(tokenRequests.count, 5)
        XCTAssertEqual(Array(requestOrder.suffix(8)), ["settings", "token", "settings", "token", "settings", "token", "settings", "token"])
        XCTAssertEqual(analytics.loggedAnalyticPayloads(withEventName: "onramp.crypto_payment_token_created").count, 1)
        XCTAssertEqual(analytics.loggedAnalyticPayloads(withEventName: "onramp.error_occurred").count, 14)
    }

    private func assertBothTokenMethodsFail(
        _ coordinator: CryptoOnrampCoordinator,
        check: (Error) -> Void
    ) async {
        for withDetails in [false, true] {
            do {
                if withDetails {
                    _ = try await coordinator.createCryptoPaymentTokenWithDetails()
                } else {
                    _ = try await coordinator.createCryptoPaymentToken()
                }
                XCTFail("Expected token creation to fail")
            } catch {
                check(error)
            }
        }
    }

    private func cardFixture(funding: String? = "debit", brand: String = "visa", last4: String? = "4242") -> [String: Any] {
        var card: [String: Any] = ["brand": brand, "exp_month": 12, "exp_year": 2030]
        card["funding"] = funding
        card["last4"] = last4
        return card
    }

    @MainActor
    private func makeCoordinator(
        cryptoCustomerID: String? = nil,
        countryHint: String? = nil,
        analyticsClient: MockAnalyticsClientV2? = nil
    ) async throws -> CryptoOnrampCoordinator {
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
            if let onTokenRequest {
                if Thread.isMainThread {
                    MainActor.assumeIsolated { onTokenRequest() }
                } else {
                    DispatchQueue.main.sync { onTokenRequest() }
                }
            }
            return tokenFailure ?? HTTPStubsResponse(jsonObject: ["id": "cpt_test"], statusCode: 200, headers: nil)
        }
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_partner"
        if let analyticsClient {
            let linkController = try await LinkController.create(apiClient: apiClient, mode: .payment, requestSurface: .cryptoOnramp)
            return CryptoOnrampCoordinator(
                linkController: linkController,
                cryptoCustomerID: cryptoCustomerID,
                apiClient: apiClient,
                appearance: .init(),
                analyticsClient: CryptoOnrampAnalyticsClient(analyticsClient: analyticsClient),
                additionalSDKVersions: [],
                countryHint: countryHint
            )
        }
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
    private func stagePaymentMethod(
        _ id: String,
        coordinator: CryptoOnrampCoordinator,
        context: STPApplePayContext,
        card: [String: Any]? = nil
    ) async throws {
        var fields: [String: Any] = ["id": id, "created": 0, "livemode": false, "type": "card"]
        fields["card"] = card
        let data = try JSONSerialization.data(withJSONObject: fields)
        let paymentMethod: StripeAPI.PaymentMethod = try StripeJSONDecoder.decode(jsonData: data)
        let result = try await coordinator.applePayContext(context, didCreatePaymentMethod: paymentMethod, paymentInformation: PKPayment())
        XCTAssertEqual(result, STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT)
    }

    @MainActor
    private func collectApplePay(
        _ coordinator: CryptoOnrampCoordinator,
        paymentMethodID: String = "pm_original",
        card: [String: Any]? = nil
    ) async throws {
        let context = try await beginApplePay(coordinator)
        try await stagePaymentMethod(paymentMethodID, coordinator: coordinator, context: context, card: card)
        coordinator.applePayContext(context, didCompleteWith: .success, error: nil)
    }

    private func assertKYCRegionChanged(_ coordinator: CryptoOnrampCoordinator, file: StaticString = #filePath, line: UInt = #line) async throws {
        let tokenCount = tokenRequests.count
        do {
            _ = try await coordinator.createCryptoPaymentToken()
            XCTFail("Expected KYC region change", file: file, line: line)
        } catch {
            XCTAssertTrue(error is PaymentMethodKYCRegionChangedError, "Unexpected error: \(error)", file: file, line: line)
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
