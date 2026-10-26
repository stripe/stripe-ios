//
//  STPAPIClient+ErrorResponseTest.swift
//  StripeCoreTests
//
//  Created by Eduardo Urias on 9/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import XCTest

class STPAPIClient_ErrorResponseTest: XCTestCase {
    func testResponseWithoutMessagePreservesGenericDescription() throws {
        for includeRequestID in [false, true] {
            // Given an API error with no message or recognized error code
            let data = try JSONSerialization.data(withJSONObject: ["error": ["type": "api_error"]])
            let response = HTTPURLResponse(
                url: URL(string: "https://api.stripe.com/v1/payment_methods")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Request-Id": "req_no_message"]
            )

            // When it is decoded with or without request IDs in descriptions
            let result: Result<EmptyResponse, Error> = STPAPIClient.decodeResponse(
                data: data,
                error: nil,
                response: response,
                includeRequestIDInDescription: includeRequestID
            )
            guard case .failure(let error) = result else {
                return XCTFail("Expected an API error")
            }
            let stripeError = try XCTUnwrap(error as? StripeError)

            // Then the generic description remains present and only the suffix changes
            let expected = NSError.stp_unexpectedErrorMessage() + (includeRequestID ? " (req_no_message)" : "")
            XCTAssertEqual(stripeError.errorDescription, expected)
            XCTAssertEqual((error as NSError).localizedDescription, expected)
            XCTAssertEqual(try XCTUnwrap(NSError.stp_error(from: stripeError)).localizedDescription, expected)
        }
    }

    /// Response is an error, error code is a known error code, and no message is present,
    /// `localizedDescription` is filled by a default error message.
    func testResponse_WithKnownErrorCode_noMessage() throws {
        let response = [
            "error": [
                "type": "card_error",
                "code": "incorrect_number",
            ],
        ]

        let responseData = try JSONSerialization.data(withJSONObject: response, options: [])
        let result: Result<EmptyResponse, Error> = STPAPIClient.decodeResponse(
            data: responseData,
            error: nil,
            response: nil
        )

        switch result {
        case .failure(let error):
            XCTAssertEqual(
                error.localizedDescription,
                NSError.stp_cardErrorInvalidNumberUserMessage()
            )
        case .success:
            XCTFail("The request should not have succeeded")
        }
    }

    /// Response is an error, error code is a known error code, and message is present,
    /// `localizedDescription` is filled with the provided message.
    func testResponse_WithKnownErrorCode_messagePresent() throws {
        let response = [
            "error": [
                "type": "card_error",
                "message": "some message",
                "code": "incorrect_number",
            ],
        ]

        let responseData = try JSONSerialization.data(withJSONObject: response, options: [])
        let result: Result<EmptyResponse, Error> = STPAPIClient.decodeResponse(
            data: responseData,
            error: nil,
            response: nil
        )

        switch result {
        case .failure(let error):
            XCTAssertEqual(
                error.localizedDescription,
                "some message"
            )
        case .success:
            XCTFail("The request should not have succeeded")
        }
    }

    /// Response is an error, error code is not present.
    func testResponse_WithNoErrorCode() throws {
        let response = [
            "error": [
                "type": "card_error",
                "message": "some message",
            ],
        ]

        let responseData = try JSONSerialization.data(withJSONObject: response, options: [])
        let result: Result<EmptyResponse, Error> = STPAPIClient.decodeResponse(
            data: responseData,
            error: nil,
            response: nil
        )

        switch result {
        case .failure(let error):
            XCTAssertEqual(error.localizedDescription, "some message")
        case .success:
            XCTFail("The request should not have succeeded")
        }
    }

    /// Response is an error, error code is empty.
    func testResponse_WithEmptyErrorCode() throws {
        let response = [
            "error": [
                "type": "card_error",
                "message": "some message",
                "code": "",
            ],
        ]

        let responseData = try JSONSerialization.data(withJSONObject: response, options: [])
        let result: Result<EmptyResponse, Error> = STPAPIClient.decodeResponse(
            data: responseData,
            error: nil,
            response: nil
        )

        switch result {
        case .failure(let error):
            XCTAssertEqual(error.localizedDescription, "some message")
        case .success:
            XCTFail("The request should not have succeeded")
        }
    }

    /// Response is an error, error code is invalid.
    func testResponse_WithInvalidErrorCode() throws {
        let response = [
            "error": [
                "type": "card_error",
                "message": "some message",
                "code": "garbage",
            ],
        ]

        let responseData = try JSONSerialization.data(withJSONObject: response, options: [])
        let result: Result<EmptyResponse, Error> = STPAPIClient.decodeResponse(
            data: responseData,
            error: nil,
            response: nil
        )

        switch result {
        case .failure(let error):
            XCTAssertEqual(error.localizedDescription, "some message")
        case .success:
            XCTFail("The request should not have succeeded")
        }
    }
}
