import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) import StripeCore
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

    // Exercise the modern Decodable and legacy APIResponseDecodable request paths.
    private func requestErrors(isTestmode: Bool, requestID: String?, type: String = "invalid_request_error") async throws -> [Error] {
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = isTestmode ? "pk_test_example" : "pk_live_example"
        stub { $0.url?.path == "/v1/payment_methods" } response: { _ in
            HTTPStubsResponse(
                jsonObject: ["error": ["type": type, "message": "Your card was declined."]],
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
