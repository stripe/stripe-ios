//
//  APIRequest.swift
//  StripePayments
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

let HTTPMethodPOST = "POST"
let HTTPMethodGET = "GET"
let HTTPMethodDELETE = "DELETE"
let JSONKeyObject = "object"

/// - Note: The shape of this class is only for backwards compatibility with `STPAPIResponseDecodable` public API bindings.
///         If you're not dealing with `STPAPIResponseDecodable` objects, use STPAPIClient's `get`, `post`, etc. methods.
@_spi(STP) public class APIRequest<ResponseType: STPAPIResponseDecodable>: NSObject {
    @_spi(STP) public typealias STPAPIResponseBlock = (ResponseType?, HTTPURLResponse?, Error?) ->
        Void

    @_spi(STP) public class func post(
        with apiClient: STPAPIClient,
        endpoint: String,
        additionalHeaders: [String: String] = [:],
        parameters: [String: Any],
        completion: @escaping STPAPIResponseBlock
    ) {
        // Build url
        let url = apiClient.apiURL.appendingPathComponent(endpoint)

        // Setup request
        var request = apiClient.configuredRequest(for: url, additionalHeaders: additionalHeaders)
        request.httpMethod = HTTPMethodPOST
        request.stp_setFormPayload(parameters)

        // Perform request
        apiClient.urlSession.stp_performDataTask(
            with: request as URLRequest,
            completionHandler: { body, response, error in
                self.parseResponse(response, method: "POST", body: body, error: error, completion: completion)
            }
        )
    }

    /// Async version
    @_spi(STP) public class func post(
        with apiClient: STPAPIClient,
        endpoint: String,
        additionalHeaders: [String: String] = [:],
        parameters: [String: Any]
    ) async throws -> (ResponseType) {
        return try await withCheckedThrowingContinuation { continuation in
            post(with: apiClient, endpoint: endpoint, additionalHeaders: additionalHeaders, parameters: parameters) { responseObject, _, error in
                guard let responseObject else {
                    continuation.resume(throwing: error ?? NSError.stp_genericFailedToParseResponseError())
                    return
                }
                continuation.resume(returning: responseObject)
            }
        }
    }

    @_spi(STP) public class func getWith(
        _ apiClient: STPAPIClient,
        endpoint: String,
        additionalHeaders: [String: String] = [:],
        parameters: [String: Any],
        completion: @escaping STPAPIResponseBlock
    ) {
        // Build url
        let url = apiClient.apiURL.appendingPathComponent(endpoint)

        // Setup request
        var request = apiClient.configuredRequest(for: url, additionalHeaders: additionalHeaders)
        request.stp_addParameters(toURL: parameters)
        request.httpMethod = HTTPMethodGET

        // Perform request
        apiClient.urlSession.stp_performDataTask(
            with: request as URLRequest,
            completionHandler: { body, response, error in
                self.parseResponse(response, method: "GET", body: body, error: error, completion: completion)
            }
        )
    }

    /// Async version
    @_spi(STP) public class func getWith(
        _ apiClient: STPAPIClient,
        endpoint: String,
        additionalHeaders: [String: String] = [:],
        parameters: [String: Any]
    ) async throws -> ResponseType {
        return try await withCheckedThrowingContinuation { continuation in
            getWith(apiClient, endpoint: endpoint, additionalHeaders: additionalHeaders, parameters: parameters) { responseObject, _, error in
                guard let responseObject else {
                    continuation.resume(throwing: error ?? NSError.stp_genericFailedToParseResponseError())
                    return
                }
                continuation.resume(returning: responseObject)
            }
        }
    }

    @_spi(STP) public class func delete(
        with apiClient: STPAPIClient,
        endpoint: String,
        additionalHeaders: [String: String] = [:],
        parameters: [String: Any],
        completion: @escaping STPAPIResponseBlock
    ) {
        // Build url
        let url = apiClient.apiURL.appendingPathComponent(endpoint)

        // Setup request
        var request = apiClient.configuredRequest(for: url, additionalHeaders: additionalHeaders)
        request.stp_addParameters(toURL: parameters)
        request.httpMethod = HTTPMethodDELETE

        // Perform request
        apiClient.urlSession.stp_performDataTask(
            with: request as URLRequest,
            completionHandler: { body, response, error in
                self.parseResponse(response, method: "DELETE" ,body: body, error: error, completion: completion)
            }
        )
    }

    class func parseResponse(
        _ response: URLResponse?,
        method: String,
        body: Data?,
        error: Error?,
        completion: @escaping (ResponseType?, HTTPURLResponse?, Error?) -> Void
    ) {
        // Derive HTTP URL response
        var httpResponse: HTTPURLResponse?
        if response is HTTPURLResponse {
            httpResponse = response as? HTTPURLResponse
        }

        // Wrap completion block with main thread dispatch
        let safeCompletion: ((ResponseType?, Error?) -> Void) = { responseObject, responseError in
            stpDispatchToMainThreadIfNecessary({
                completion(responseObject, httpResponse, responseError)
            })
        }

        if error != nil {
            // Forward NSURLSession error
            return safeCompletion(nil, error)
        }

        // Parse JSON response body
        var jsonDictionary: [AnyHashable: Any]?
        if let body = body {
            do {
                jsonDictionary =
                    try JSONSerialization.jsonObject(with: body, options: []) as? [AnyHashable: Any]
            } catch {

            }
        }

        // HACK:
        // STPEmptyStripeResponse will always parse successfully and never return an error, as we're
        // not looking at the HTTP error code or the error dictionary.
        // I'm afraid this will cause issues if anyone is depending on the old behavior, so let's treat
        // STPEmptyStripeResponse as special.
        // We probably always want errors to override object deserialization: re-evaluate
        // this hack when building the new API client.
        if ResponseType.self == STPEmptyStripeResponse.self {
            if let error: Error =
                NSError.stp_error(fromStripeResponse: jsonDictionary, httpResponse: httpResponse)
            {
                safeCompletion(nil, error)
            } else if let responseObject = ResponseType.decodedObject(
                fromAPIResponse: jsonDictionary
            ) {
                safeCompletion(responseObject, nil)
            } else {
                safeCompletion(nil, NSError.stp_genericFailedToParseResponseError())
            }
            return
        }
        // END OF STPEmptyStripeResponse HACK

        #if DEBUG
        if let httpResponse,
           let requestId = httpResponse.value(forHTTPHeaderField: "request-id"),
           let url = httpResponse.value(forKey: "URL") as? URL {
            print("[Stripe SDK]: \(method) \"\(url.relativePath)\" \(httpResponse.statusCode) \(requestId)")
        }
        #endif

        if let responseObject = ResponseType.decodedObject(fromAPIResponse: jsonDictionary) {
            safeCompletion(responseObject, nil)
        } else {
            let error: Error =
                NSError.stp_error(fromStripeResponse: jsonDictionary, httpResponse: httpResponse)
                ?? NSError.stp_genericFailedToParseResponseError()
            safeCompletion(nil, error)
        }
    }

}
