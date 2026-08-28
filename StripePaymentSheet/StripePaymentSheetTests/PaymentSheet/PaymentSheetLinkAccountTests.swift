//
//  PaymentSheetLinkAccountTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

import OHHTTPStubs
import OHHTTPStubsSwift
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

final class PaymentSheetLinkAccountTests: APIStubbedTestCase {
    override func tearDown() {
        PaymentSheetLinkAccount.forcedConsumerLinkBrandForTesting = nil
        super.tearDown()
    }

    func testMakePaymentMethodParams() {
        let sut = makeSUT()

        let paymentDetails = makePaymentDetailsStub()
        let result = sut.makePaymentMethodParams(from: paymentDetails, cvc: nil, billingPhoneNumber: nil, allowRedisplay: nil)

        XCTAssertEqual(result?.type, .link)
        XCTAssertEqual(result?.link?.paymentDetailsID, "1")
        XCTAssertEqual(
            result?.link?.credentials as? [String: String],
            [
                "consumer_session_client_secret": "client_secret"
            ]
        )
        XCTAssertNil(result?.link?.additionalAPIParameters["card"])
    }

    func testMakePaymentMethodParams_withCVC() {
        let sut = makeSUT()

        let paymentDetails = makePaymentDetailsStub()
        let result = sut.makePaymentMethodParams(from: paymentDetails, cvc: "1234", billingPhoneNumber: nil, allowRedisplay: nil)

        XCTAssertEqual(
            result?.link?.additionalAPIParameters["card"] as? [String: String],
            [
                "cvc": "1234"
            ]
        )
    }

    func testMakePaymentMethodParams_withAllowRedisplay() {
        let sut = makeSUT()

        let paymentDetails = makePaymentDetailsStub()
        let result = sut.makePaymentMethodParams(from: paymentDetails, cvc: "1234", billingPhoneNumber: nil, allowRedisplay: .always)

        XCTAssertEqual(result?.allowRedisplay, .always)
    }

    @MainActor
    func testRefreshesWhenNeeded() {
        let sut = makeSUT()
        let listedPaymentDetailsExp = expectation(description: "Lists payment details")
        let refreshExp = expectation(description: "Refreshes when needed")
        // Set up a stub to return a 401 with the wrong key, otherwise return an empty PM list
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("consumers/payment_details/list") ?? false
        } response: { urlRequest in
            // Check to make sure we've passed the correct secret key
            let body = String(data: urlRequest.httpBodyOrBodyStream ?? Data(), encoding: .utf8) ?? ""
            if !body.contains("unexpired_key") {
                // If it isn't the unexpired key, force a refresh by sending the correct error:
                let errorResponse = [
                    "error":
                        [
                            "message": "Fake invalid consumer session error.",
                            "code": "consumer_session_credentials_invalid",
                            "type": "invalid_request_error",
                        ],
                ]
                return HTTPStubsResponse(jsonObject: errorResponse, statusCode: 401, headers: nil)
            }

            // If we did succeed, send an empty payment details list (which will be treated as a successful response).
            let paymentDetailsEmptyList = ["redacted_payment_details": []]
            return HTTPStubsResponse(jsonObject: paymentDetailsEmptyList, statusCode: 200, headers: nil)
        }

        sut.paymentSheetLinkAccountDelegate = PaymentSheetLinkAccountDelegateStub(expectation: refreshExp)
        // List the payment details. This will fail, refresh the token, then succeed.
        sut.listPaymentDetails(supportedTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)]) { result in
            switch result {
            case .success:
                listedPaymentDetailsExp.fulfill()
            case .failure:
                XCTFail("Should not have failed")
            }
        }
        waitForExpectations(timeout: 5)
    }

    func testRecordConnectionsConsentAcquired_sendsExpectedConsentJSON() async throws {
        let sut = makeSUT()
        let consentText = "Rocket Deliveries can access account and ownership details, balances, and transactions."

        var capturedFormFields: [String: String] = [:]
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("consumers/connections_consent_acquired") ?? false
        } response: { urlRequest in
            let body = String(data: urlRequest.httpBodyOrBodyStream ?? Data(), encoding: .utf8) ?? ""
            capturedFormFields = Self.decodeFormFields(from: body)
            return HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        _ = try await sut.recordConnectionsConsentAcquired(localizedConsentText: consentText)

        let consentJSONString = try XCTUnwrap(capturedFormFields["consent"])
        let consentJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(consentJSONString.utf8)) as? [String: Any]
        )
        XCTAssertEqual(consentJSON as? [String: String], ["localizedConsent": consentText])
        XCTAssertNil(consentJSON["consentMessageTemplate"])

        XCTAssertEqual(capturedFormFields["credentials[consumer_session_client_secret]"], "client_secret")
        XCTAssertEqual(capturedFormFields["request_surface"], "ios_payment_element")
    }

    /// Decodes an `application/x-www-form-urlencoded` request body into a flat `[key: value]` map, keeping
    /// bracketed keys (e.g. `credentials[consumer_session_client_secret]`) as-is rather than nesting them.
    private static func decodeFormFields(from body: String) -> [String: String] {
        var fields: [String: String] = [:]
        for pair in body.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
            let value = String(parts[1]).replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String(parts[1])
            fields[key] = value
        }
        return fields
    }

    @MainActor
    func testRecordConnectionsConsentAcquired_retriesOnAuthError() async throws {
        let sut = makeSUT()
        let refreshExp = expectation(description: "Refreshes when needed")

        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("consumers/connections_consent_acquired") ?? false
        } response: { urlRequest in
            let body = String(data: urlRequest.httpBodyOrBodyStream ?? Data(), encoding: .utf8) ?? ""
            if !body.contains("unexpired_key") {
                let errorResponse = [
                    "error":
                        [
                            "message": "Fake invalid consumer session error.",
                            "code": "consumer_session_credentials_invalid",
                            "type": "invalid_request_error",
                        ],
                ]
                return HTTPStubsResponse(jsonObject: errorResponse, statusCode: 401, headers: nil)
            }

            return HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        sut.paymentSheetLinkAccountDelegate = PaymentSheetLinkAccountDelegateStub(expectation: refreshExp)

        _ = try await sut.recordConnectionsConsentAcquired(localizedConsentText: "consent text")
        waitForExpectations(timeout: 5)
    }

    func testMeetsMinimumAuthenticationLevel_meets() {
        let session = ConsumerSession.make(
            clientSecret: "secret",
            emailAddress: "user@example.com",
            redactedFormattedPhoneNumber: "(***) *** **55",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: nil,
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: nil,
            currentAuthenticationLevel: .oneFactorAuth,
            minimumAuthenticationLevel: .oneFactorAuth
        )
        XCTAssertTrue(session.meetsMinimumAuthenticationLevel)
    }

    func testMeetsMinimumAuthenticationLevel_doesNotMeet() {
        let session = ConsumerSession.make(
            clientSecret: "secret",
            emailAddress: "user@example.com",
            redactedFormattedPhoneNumber: "(***) *** **55",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: nil,
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: nil,
            currentAuthenticationLevel: .notAuthenticated,
            minimumAuthenticationLevel: .oneFactorAuth
        )
        XCTAssertFalse(session.meetsMinimumAuthenticationLevel)
    }

    func testNoRefreshWhenNotRequested() {
        let sut = makeSUT()
        let listedPaymentDetailsExp = expectation(description: "Lists payment details")

        // Set up a stub to return a 401 with the wrong key, otherwise return an empty PM list
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("consumers/payment_details/list") ?? false
        } response: { urlRequest in
            // Check to make sure we've passed the correct secret key
            let body = String(data: urlRequest.httpBodyOrBodyStream ?? Data(), encoding: .utf8) ?? ""
            if !body.contains("unexpired_key") {
                // If it isn't the unexpired key, force a refresh by sending the correct error:
                let errorResponse = [
                    "error":
                        [
                            "message": "Fake invalid consumer session error.",
                            "code": "consumer_session_credentials_invalid",
                            "type": "invalid_request_error",
                        ],
                ]
                return HTTPStubsResponse(jsonObject: errorResponse, statusCode: 401, headers: nil)
            }

            // If we did succeed, send an empty payment details list (which will be treated as a successful response).
            let paymentDetailsEmptyList = ["redacted_payment_details": []]
            return HTTPStubsResponse(jsonObject: paymentDetailsEmptyList, statusCode: 200, headers: nil)
        }

        // List the payment details. This will fail, refresh the token, then succeed.
        sut.listPaymentDetails(
            supportedTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            shouldRetryOnAuthError: false
        ) { result in
            switch result {
            case .success:
                XCTFail("Should not have succeeded")
            case .failure:
                listedPaymentDetailsExp.fulfill()
            }
        }
        waitForExpectations(timeout: 5)
    }

    func testLinkBrand_usesVerifiedSessionBrand() {
        let session = makeVerifiedSession()
        session.linkBrand = .onelink

        let sut = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: session,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        XCTAssertEqual(sut.linkBrand, .onelink)
    }

    func testLinkBrand_forceOnelinkConsumerOnlyAppliesAfterVerifiedConsumerSessionExists() {
        PaymentSheetLinkAccount.forcedConsumerLinkBrandForTesting = .onelink

        let signedOutAccount = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: nil,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        XCTAssertNil(signedOutAccount.linkBrand)

        let unverifiedSession = LinkStubs.consumerSession()
        unverifiedSession.linkBrand = .link
        let unverifiedAccount = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: unverifiedSession,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        XCTAssertNil(unverifiedAccount.linkBrand)

        let verifiedSession = makeVerifiedSession()
        verifiedSession.linkBrand = .link
        let verifiedAccount = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: verifiedSession,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        XCTAssertEqual(verifiedAccount.linkBrand, .onelink)
    }
}

class PaymentSheetLinkAccountDelegateStub: PaymentSheetLinkAccountDelegate {
    let expectation: XCTestExpectation

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func refreshLinkSession(completion: @escaping (Result<ConsumerSession, Error>) -> Void) {
        // Return a fake session with a "good" key
        let stubSession = ConsumerSession.make(
            clientSecret: "unexpired_key",
            emailAddress: "user@example.com",
            redactedFormattedPhoneNumber: "(***) *** **55",
            unredactedPhoneNumber: "(555) 555-5555",
            phoneNumberCountry: "US",
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            mobileFallbackWebviewParams: nil
        )
        completion(.success(stubSession))
        expectation.fulfill()
    }
}

extension PaymentSheetLinkAccountTests {
    func makeVerifiedSession() -> ConsumerSession {
        return ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "user@example.com",
            redactedFormattedPhoneNumber: "(***) *** **55",
            unredactedPhoneNumber: "(555) 555-5555",
            phoneNumberCountry: "US",
            verificationSessions: [.init(type: .sms, state: .verified)],
            supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            mobileFallbackWebviewParams: nil,
            currentAuthenticationLevel: .twoFactorAuth,
            minimumAuthenticationLevel: .oneFactorAuth
        )
    }

    func makePaymentDetailsStub() -> ConsumerPaymentDetails {
        return ConsumerPaymentDetails(
            stripeID: "1",
            details: .card(card: .init(
                expiryYear: 30,
                expiryMonth: 10,
                brand: "visa",
                networks: ["visa"],
                last4: "1234",
                funding: .credit,
                checks: nil
            )),
            billingAddress: nil,
            billingEmailAddress: nil,
            nickname: nil,
            isDefault: false
        )
    }

    func makeSUT() -> PaymentSheetLinkAccount {
        return PaymentSheetLinkAccount(
            email: "user@example.com",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )
    }

}

// MARK: - FundingSource.detailsType mapping tests

final class FundingSourceDetailsTypeMappingTests: XCTestCase {

    func test_card_mapsToCardDetailsType() {
        let fundingSource = ParsedEnum(LinkSettings.FundingSource.card)
        XCTAssertEqual(fundingSource.detailsType, ParsedEnum(.card))
        XCTAssertEqual(fundingSource.detailsType.value, .card)
    }

    func test_bankAccount_mapsToBankAccountDetailsType() {
        let fundingSource = ParsedEnum(LinkSettings.FundingSource.bankAccount)
        XCTAssertEqual(fundingSource.detailsType, ParsedEnum(.bankAccount))
        XCTAssertEqual(fundingSource.detailsType.value, .bankAccount)
    }

    func test_genericType_transfersRawValue() {
        let fundingSource = ParsedEnum<LinkSettings.FundingSource>(rawValue: "PIX")
        let detailsType = fundingSource.detailsType
        XCTAssertNil(detailsType.value, "Generic funding source should produce an unparsed details type")
        XCTAssertEqual(detailsType.rawValue, "PIX", "Raw value should be preserved for generic types")
    }

    func test_genericType_appearsInIntersectionWhenConsumerSessionAlsoAdvertisesIt() {
        // If both the funding sources and the consumer session advertise a generic type,
        // it should survive the intersection even though neither side can parse it.
        let fundingSourceDetailsTypes: Set<ParsedEnum<ConsumerPaymentDetails.DetailsType>> = [
            ParsedEnum(rawValue: "PIX"),
            ParsedEnum(.card),
        ]
        let sessionTypes: Set<ParsedEnum<ConsumerPaymentDetails.DetailsType>> = [
            ParsedEnum(rawValue: "PIX"),
        ]
        let supported = fundingSourceDetailsTypes.intersection(sessionTypes)
        XCTAssertEqual(supported.count, 1)
        XCTAssertEqual(supported.first?.rawValue, "PIX")
        XCTAssertNil(supported.first?.value)
    }

    func test_genericType_isExcludedFromIntersectionWhenSessionDoesNotAdvertiseIt() {
        let fundingSourceDetailsTypes: Set<ParsedEnum<ConsumerPaymentDetails.DetailsType>> = [
            ParsedEnum(rawValue: "PIX"),
            ParsedEnum(.card),
        ]
        let sessionTypes: Set<ParsedEnum<ConsumerPaymentDetails.DetailsType>> = [
            ParsedEnum(.card),
        ]
        let supported = fundingSourceDetailsTypes.intersection(sessionTypes)
        XCTAssertEqual(supported.count, 1)
        XCTAssertEqual(supported.first?.value, .card)
    }
}

// MARK: - supportedPaymentMethodTypes tests

final class SupportedPaymentMethodTypesTests: XCTestCase {

    func test_supportedPaymentMethodTypes_returnsEmptyWhenSessionFundingSourcesEmpty() throws {
        // Given a consumer session that supports cards, but the session-level funding sources list is empty
        let consumerSession = ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "user@example.com",
            redactedFormattedPhoneNumber: "(***) *** **55",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: nil,
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: nil
        )
        let linkAccount = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: consumerSession,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        let (_, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(linkFundingSources: [])
        let result = linkAccount.supportedPaymentMethodTypes(for: elementsSession)

        XCTAssertTrue(result.isEmpty, "Should return empty array when session has no funding sources")
    }

    func test_supportedPaymentMethodTypes_returnsEmptyWhenIntersectionIsEmpty() throws {
        // Given a session that allows only bank accounts, but the consumer only supports cards
        let consumerSession = ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "user@example.com",
            redactedFormattedPhoneNumber: "(***) *** **55",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: nil,
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: nil
        )
        let linkAccount = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: consumerSession,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        let (_, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(linkFundingSources: ["BANK_ACCOUNT"])
        let result = linkAccount.supportedPaymentMethodTypes(for: elementsSession)

        XCTAssertTrue(result.isEmpty, "Should return empty array when intersection of session and consumer funding sources is empty")
    }

    func test_supportedPaymentMethodTypes_returnsCardWhenBothSidesHaveCard() throws {
        // Given a session and consumer that both support cards
        let consumerSession = ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "user@example.com",
            redactedFormattedPhoneNumber: "(***) *** **55",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: nil,
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: nil
        )
        let linkAccount = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: consumerSession,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        let (_, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(linkFundingSources: ["CARD"])
        let result = linkAccount.supportedPaymentMethodTypes(for: elementsSession)

        XCTAssertEqual(result, [.card])
    }
}
