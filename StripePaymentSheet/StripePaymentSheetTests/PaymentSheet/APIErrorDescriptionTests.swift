import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @_spi(DashboardOnly) import StripeCore
import StripeCoreTestUtils
@_spi(STP) import StripePayments
@testable import StripePaymentSheet
import XCTest

final class APIErrorDescriptionTests: APIStubbedTestCase {
    func testLiveModeAppendsRequestID() async throws {
        for error in try await requestErrors(isTestmode: false, requestID: "req_123") {
            let expected = NSError.stp_unexpectedErrorMessage() + " (req_123)"
            XCTAssertEqual(error.localizedDescription, expected)
            XCTAssertEqual(error.nonGenericDescription, expected)
            XCTAssertEqual(error.serializeForV1Analytics()["request_id"] as? String, "req_123")

            // PaymentHandler must preserve the description when it wraps the API error.
            let wrapped = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2,
                                  userInfo: [NSUnderlyingErrorKey: error])
            XCTAssertEqual(wrapped.nonGenericDescription, expected)
        }
    }

    func testTestModeKeepsExistingMessage() async throws {
        for error in try await requestErrors(isTestmode: true, requestID: "req_123") {
            XCTAssertEqual(error.localizedDescription, NSError.stp_unexpectedErrorMessage())
            XCTAssertEqual(error.nonGenericDescription, NSError.stp_unexpectedErrorMessage())
            XCTAssertEqual(error.serializeForV1Analytics()["request_id"] as? String, "req_123")
        }
    }

    func testUnknownModeKeepsExistingMessage() async throws {
        for key in ["ek_test_example", "ek_live_example", "ek_example", "unknown", ""] {
            // Given a client whose key does not tell us whether it is in live mode
            let apiClient = stubbedAPIClient()
            apiClient.publishableKey = key

            // When the API returns an error with a request ID
            for error in try await requestErrors(apiClient: apiClient, requestID: "req_unknown") {
                // Then the description is unchanged and the request ID remains available to analytics
                XCTAssertEqual(error.localizedDescription, NSError.stp_unexpectedErrorMessage())
                XCTAssertFalse(error._stp_hasRequestIDInDescription)
                XCTAssertEqual(error.serializeForV1Analytics()["request_id"] as? String, "req_unknown")
            }
        }
    }

    func testUserKeyRespectsLiveMode() async throws {
        for livemode in [false, true] {
            // Given a user key with an explicit mode
            let apiClient = stubbedAPIClient()
            apiClient.publishableKey = "uk_example"
            apiClient.userKeyLiveMode = livemode

            // When the API returns an error with a request ID
            for error in try await requestErrors(apiClient: apiClient, requestID: "req_user") {
                // Then only live mode appends the ID, while both modes preserve the metadata
                let expected = NSError.stp_unexpectedErrorMessage() + (livemode ? " (req_user)" : "")
                XCTAssertEqual(error.localizedDescription, expected)
                XCTAssertEqual(error._stp_hasRequestIDInDescription, livemode)
                XCTAssertEqual(error.serializeForV1Analytics()["request_id"] as? String, "req_user")
            }
        }
    }

    func testMissingRequestIDKeepsExistingMessage() async throws {
        for requestID: String? in [nil, ""] {
            for error in try await requestErrors(isTestmode: false, requestID: requestID) {
                XCTAssertEqual(error.localizedDescription, NSError.stp_unexpectedErrorMessage())
            }
        }
    }

    func testCardMessageIsPreservedInBothModes() async throws {
        for isTestmode in [false, true] {
            for error in try await requestErrors(isTestmode: isTestmode, requestID: "req_card", type: "card_error") {
                XCTAssertEqual(error.localizedDescription, "Your card was declined." + (isTestmode ? "" : " (req_card)"))
            }
        }
    }

    func testWrappedCardErrorsPreserveExistingBehaviorWithoutLiveRequestID() async throws {
        for isTestmode in [false, true] {
            for requestID: String? in ["req_card", nil, ""] {
                for error in try await requestErrors(isTestmode: isTestmode, requestID: requestID, type: "card_error") {
                    // Given a card error wrapped by PaymentHandler
                    let wrapped = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2,
                                          userInfo: [NSUnderlyingErrorKey: error])

                    // Then only live errors with a request ID use the new description.
                    if !isTestmode, requestID == "req_card" {
                        XCTAssertEqual(wrapped.nonGenericDescription, "Your card was declined. (req_card)")
                    } else {
                        let previousMessage = error is StripeError ? NSError.stp_unexpectedErrorMessage() : "Your card was declined."
                        XCTAssertEqual(wrapped.nonGenericDescription, previousMessage)
                    }
                }
            }
        }
    }

    func testLegacyApplePayConversionPreservesDescription() async throws {
        for isTestmode in [false, true] {
            for type in ["card_error", "invalid_request_error"] {
                // Given a modern API error with a request ID
                let errors = try await requestErrors(isTestmode: isTestmode, requestID: "req_apple_pay", type: type)
                let modern = try XCTUnwrap(errors.first as? StripeError)

                // When the legacy Apple Pay delegate converts it to NSError
                let converted = try XCTUnwrap(NSError.stp_error(from: modern))

                // Then the description and metadata survive without appending the ID twice.
                XCTAssertEqual(converted.localizedDescription, modern.localizedDescription)
                XCTAssertEqual(converted.userInfo[STPError.stripeErrorTypeKey] as? String, type)
                XCTAssertEqual(converted.userInfo[STPError.errorMessageKey] as? String, "Your card was declined.")
                XCTAssertEqual(converted.serializeForV1Analytics()["request_id"] as? String, "req_apple_pay")
                XCTAssertEqual(converted._stp_hasRequestIDInDescription, !isTestmode)
                XCTAssertEqual(converted.userInfo[STPError.stripeDeclineCodeKey] as? String, type == "card_error" ? "insufficient_funds" : nil)
                XCTAssertEqual((converted.userInfo["payment_intent"] as? [String: Any])?["id"] as? String, "pi_example")
                if !isTestmode {
                    let wrapped = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2,
                                          userInfo: [NSUnderlyingErrorKey: converted])
                    XCTAssertEqual(wrapped.nonGenericDescription, modern.localizedDescription)
                }
            }
        }
    }

    // Exercise the modern Decodable and legacy APIResponseDecodable request paths.
    private func requestErrors(isTestmode: Bool, requestID: String?, type: String = "invalid_request_error") async throws -> [Error] {
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = isTestmode ? "pk_test_example" : "pk_live_example"
        return try await requestErrors(apiClient: apiClient, requestID: requestID, type: type)
    }

    private func requestErrors(apiClient: STPAPIClient, requestID: String?, type: String = "invalid_request_error") async throws -> [Error] {
        var errorFields: [String: Any] = [
            "type": type,
            "message": "Your card was declined.",
            "payment_intent": ["object": "payment_intent", "id": "pi_example"],
        ]
        if type == "card_error" {
            errorFields["code"] = "card_declined"
            errorFields["decline_code"] = "insufficient_funds"
        }
        stub { $0.url?.path == "/v1/payment_methods" } response: { _ in
            HTTPStubsResponse(
                jsonObject: ["error": errorFields],
                statusCode: 400,
                headers: requestID.map { ["Request-Id": $0] }
            )
        }

        let modern: Result<EmptyResponse, Error> = await withCheckedContinuation { continuation in
            apiClient.get(resource: "payment_methods", parameters: [:]) { result in
                continuation.resume(returning: result)
            }
        }
        let legacy: Error? = await withCheckedContinuation { continuation in
            APIRequest<STPCard>.getWith(apiClient, endpoint: "payment_methods", parameters: [:]) { _, _, error in
                continuation.resume(returning: error)
            }
        }
        guard case .failure(let modernError) = modern else {
            XCTFail("Expected the modern request to fail")
            return []
        }
        let legacyError = try XCTUnwrap(legacy)
        return [modernError, legacyError]
    }
}
