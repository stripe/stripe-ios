//
//  APIErrorTestHelpers.swift
//  StripeFinancialConnectionsTests
//
//  Created by Mat Schmid on 2026-08-12.
//

import Foundation
@_spi(STP) import StripeCore

private enum APIErrorTestHelpersError: Error {
    case couldNotBuildResponse
    case unexpectedlyDecodedErrorBody
}

/// A response type that can never be decoded from an error body, so that `decodeResponse`
/// always takes its error-parsing path.
private struct NeverDecodableResponse: Decodable {
    let fieldThatNeverAppearsInAnErrorBody: String
}

/// Builds the `StripeError.apiError` that the SDK would produce for a failed API request.
///
/// `StripeAPIError.allResponseFields` (where `extra_fields` lives) can only be populated by
/// decoding a real response body, so this goes through the same decoding path production does.
func MakeStripeAPIError(
    statusCode: Int,
    extraFields: [String: Any]? = nil,
    message: String = "Something went wrong.",
    type: String = "invalid_request_error"
) throws -> Error {
    var error: [String: Any] = [
        "type": type,
        "message": message,
    ]
    error["extra_fields"] = extraFields

    let data = try JSONSerialization.data(withJSONObject: ["error": error])
    guard
        let url = URL(string: "https://api.stripe.com/v1/connections/auth_sessions/accounts"),
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
    else {
        throw APIErrorTestHelpersError.couldNotBuildResponse
    }

    let result: Result<NeverDecodableResponse, Error> = STPAPIClient.decodeResponse(
        data: data,
        error: nil,
        response: response
    )
    switch result {
    case .success:
        throw APIErrorTestHelpersError.unexpectedlyDecodedErrorBody
    case .failure(let error):
        return error
    }
}
