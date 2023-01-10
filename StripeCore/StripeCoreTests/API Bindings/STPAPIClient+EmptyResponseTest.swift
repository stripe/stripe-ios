//
//  STPAPIClient+EmptyResponseTest.swift
//  StripeCoreTests
//
//  Created by Jaime Park on 1/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import XCTest

class STPAPIClient_EmptyResponseTest: XCTestCase {
    /// Response is an error; Error is nil.
    ///
    /// Should result in a failure.`
    func testEmptyResponse_WithErrorResponse() throws {
        let response = [
            "error": [
                "type": "api_error",
                "message": "some message",
            ],
        ]

        let responseData = try JSONSerialization.data(withJSONObject: response, options: [])
        let result: Result<EmptyResponse, Error> = STPAPIClient.decodeResponse(
            data: responseData,
            error: nil,
            response: HTTPURLResponse(
                url: URL(string: "https://www.stripe.com")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )
        )

        switch result {
        case .success:
            XCTFail("The request should not have succeeded")
        case .failure(let error):
            if let stripeError = error as? StripeError, case .apiError(let apiError) = stripeError {
                XCTAssert(apiError.statusCode == 400, "expected status code to be set")
            } else {
                XCTFail("The error should have been an `.apiError`")
            }
        }
    }

    /// Response is an empty response; Error is not nil.
    ///
    /// Should result in a failure.
    func testEmptyResponse_WithError() throws {
        let responseData = try JSONSerialization.data(withJSONObject: [:], options: [])
        let result: Result<EmptyResponse, Error> = STPAPIClient.decodeResponse(
            data: responseData,
            error: NSError.stp_genericConnectionError(),
            response: nil
        )

        guard case .failure = result else {
            XCTFail("The request should not have succeeded")
            return
        }
    }

    /// Response is an empty response; Error is nil.
    ///
    /// Should result in a success.
    func testEmptyResponse_NoError() throws {
        let responseData = try JSONSerialization.data(withJSONObject: [:], options: [])
        let result: Result<EmptyResponse, Error> = STPAPIClient.decodeResponse(
            data: responseData,
            error: nil,
            response: nil
        )

        guard case .success = result else {
            XCTFail("The request should have succeeded")
            return
        }
    }
}
