// Copyright © 2026 Stripe, Inc. All rights reserved.

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

final class LinkAuthAPITests: STPNetworkStubbingTestCase {
    func testLookupDecodesPhoneSettingsAndUnknownFactorWithoutDroppingIt() throws {
        var session = sessionJSON
        session["available_verification_factors"] = [
            ["type": "NEW_FACTOR", "provides_further_verification": true, "temporarily_disabled": false, "id": "unknown"],
            ["type": "EMAIL", "provides_further_verification": true, "temporarily_disabled": false, "id": "email_factor"],
        ]
        let response: ConsumerSession.LookupResponse = try decode([
            "exists": true, "consumer_session": session, "publishable_key": "pk_test_consumer",
            "settings": ["email_otp_requires_additional_info": true],
        ])
        guard case .found(let account) = response.responseType else { return XCTFail("Expected an account") }
        XCTAssertEqual(account.settings?.emailOtpRequiresAdditionalInfo, true)
        XCTAssertEqual(account.consumerSession.redactedPhoneNumber, "+1********23")
        XCTAssertEqual(account.consumerSession.availableVerificationFactors?.count, 2)
        XCTAssertEqual(account.consumerSession.availableVerificationFactors?.first?.type, .unparsable)
        XCTAssertEqual(account.consumerSession.availableVerificationFactors?.last?.type, .email)
    }

    func testMissingOrUnknownAuthenticationLevelsNeverSatisfyAuthentication() throws {
        for (current, minimum) in [(nil, "1FA"), ("1FA", nil), ("FUTURE", "1FA"), ("2FA", "FUTURE"), ("FUTURE", "FUTURE")] as [(String?, String?)] {
            var json = sessionJSON
            json["current_authentication_level"] = current
            json["minimum_authentication_level"] = minimum
            let session: ConsumerSession = try decode(json)
            XCTAssertFalse(session.meetsMinimumAuthenticationLevel)
        }
    }

    func testUnknownVerificationSessionAndWebRequirementDecodeSafely() throws {
        var json = sessionJSON
        json["verification_sessions"] = [["type": "FUTURE", "state": "FUTURE"]]
        json["mobile_fallback_webview_params"] = ["webview_requirement_type": "FUTURE"]
        let session: ConsumerSession = try decode(json)
        XCTAssertEqual(session.verificationSessions.first?.type, .unparsable)
        XCTAssertEqual(session.verificationSessions.first?.state, .unparsable)
        XCTAssertEqual(session.mobileFallbackWebviewParams?.webviewRequirementType, .unparsable)
    }

    func testEmailResendIncludesPhoneAndOriginalEmailButNoFactorIDOrSMSResendFlag() {
        let completed = expectation(description: "Email verification started")
        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
            XCTAssertEqual(params["type"], "EMAIL")
            XCTAssertNil(params["verification_factor_id"])
            XCTAssertEqual(params["account_phone_number"], "+14155550123")
            XCTAssertEqual(params["email_address"], "jane@example.com")
            XCTAssertEqual(params["credentials[consumer_session_client_secret]"], "secret")
            XCTAssertNil(params["is_resend_sms_code"])
            return self.response(type: "EMAIL")
        }
        STPAPIClient(publishableKey: "pk_test_auth").startLinkVerification(for: "secret", type: .email, emailAddress: "Jane@example.com", accountPhoneNumber: "+14155550123", isResending: true) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.verificationSessionId, "verification_123")
                XCTAssertEqual(response.consumerSession.verificationSessions.first?.type, .email)
            case .failure(let error): XCTFail("Unexpected error: \(error)")
            }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 5)
    }

    func testSMSResendOmitsPhoneAndFactorIDAndIncludesSMSResendFlag() {
        let completed = expectation(description: "SMS resent")
        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
            XCTAssertEqual(params["type"], "SMS")
            XCTAssertEqual(params["is_resend_sms_code"], "true")
            XCTAssertNil(params["account_phone_number"])
            XCTAssertNil(params["verification_factor_id"])
            return self.response(type: "SMS")
        }
        STPAPIClient(publishableKey: "pk_test_auth").startLinkVerification(for: "secret", type: .sms, emailAddress: nil, accountPhoneNumber: "+14155550123", isResending: true) { result in
            if case .failure(let error) = result { XCTFail("Unexpected error: \(error)") }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 5)
    }

    func testSMSAndEmailStartResolveByTypeEvenWhenLookupHasFactorIDs() throws {
        for type in [SupportedVerificationType.sms, .email] {
            // Given an account whose lookup response includes an opaque factor ID.
            var json = sessionJSON
            json["available_verification_factors"] = [[
                "type": type.rawValue, "id": "lookup_factor_id",
                "provides_further_verification": true, "temporarily_disabled": false,
            ],
            ]
            let session: ConsumerSession = try decode(json)
            let account = PaymentSheetLinkAccount(email: session.emailAddress, session: session, publishableKey: "pk_test_consumer", displayablePaymentDetails: nil, apiClient: STPAPIClient(publishableKey: "pk_test_auth"), useMobileEndpoints: true, canSyncAttestationState: false)
            XCTAssertEqual(account.currentSession?.availableVerificationFactors?.first?.id, "lookup_factor_id")
            let completed = expectation(description: "\(type.rawValue) verification started")
            stub(condition: isPath("/v1/consumers/sessions/start_verification")) { request in
                // Then the request selects the factor by type without forwarding the lookup ID.
                let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
                XCTAssertEqual(params["type"], type.rawValue)
                XCTAssertNil(params["verification_factor_id"])
                XCTAssertNil(params["is_resend_sms_code"])
                return self.response(type: type.rawValue)
            }

            // When starting the initial OTP challenge through the account transport.
            account.startAuthVerification(type: type, phoneNumber: nil, isResending: false) { result in
                if case .failure(let error) = result { XCTFail("Unexpected error: \(error)") }
                completed.fulfill()
            }
            wait(for: [completed], timeout: 5)
            HTTPStubs.removeAllStubs()
        }
    }

    func testEmailConfirmIsResolvedByTypeAndPreservesConsent() {
        let completed = expectation(description: "Email confirmed")
        stub(condition: isPath("/v1/consumers/sessions/confirm_verification")) { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
            XCTAssertEqual(params["type"], "EMAIL")
            XCTAssertEqual(params["code"], "123456")
            XCTAssertEqual(params["consent_granted"], "true")
            XCTAssertNil(params["verification_session_id"])
            return self.response(type: "EMAIL")
        }
        STPAPIClient(publishableKey: "pk_test_auth").confirmLinkVerification(for: "secret", type: .email, code: "123456", consentGranted: true) { result in
            if case .failure(let error) = result { XCTFail("Unexpected error: \(error)") }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 5)
    }

    func testRefreshDeclaresTheNativeCapabilities() {
        let completed = expectation(description: "Refreshed")
        stub(condition: isPath("/v1/consumers/sessions/refresh")) { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
            let declared = params.filter { $0.key.hasPrefix("supported_verification_types[") }.map(\.value)
            XCTAssertEqual(Set(declared), Set(SupportedVerificationType.nativeCapabilities.map(\.rawValue)))
            return self.response(type: "SMS")
        }
        STPAPIClient(publishableKey: "pk_test_auth").refreshSession(consumerSessionClientSecret: "secret") { result in
            if case .failure(let error) = result { XCTFail("Unexpected error: \(error)") }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 5)
    }

    private var sessionJSON: [String: Any] {
        ["client_secret": "secret", "email_address": "jane@example.com", "redacted_formatted_phone_number": "(***) *** **23", "redacted_phone_number": "+1********23", "current_authentication_level": "NOT_AUTHENTICATED", "minimum_authentication_level": "1FA", "verification_sessions": []]
    }

    private func response(type: String) -> HTTPStubsResponse {
        var session = sessionJSON
        session["verification_sessions"] = [["type": type, "state": "STARTED"]]
        return HTTPStubsResponse(jsonObject: ["consumer_session": session, "verification_session_id": "verification_123"], statusCode: 200, headers: ["Content-Type": "application/json"])
    }

    private func decode<T: Decodable>(_ object: [String: Any]) throws -> T {
        try StripeJSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
