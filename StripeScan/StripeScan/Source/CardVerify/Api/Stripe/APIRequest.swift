//
//  STPAPIRequest.swift
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//
// NOTE: This is a simplified + modified version of Stripe's APIRequest. Will remove once API stack is moved to StripeCore

import Foundation

let HTTPMethodPOST = "POST"
let HTTPMethodGET = "GET"
let HTTPMethodDELETE = "DELETE"
let JSONKeyObject = "object"

/// The shape of this class is only for backwards compatibility with the rest of the codebase.
///
/// Ideally, we should do something like:
/// 1) Use Codable
/// 2) Define every Stripe API resource explicitly as a Resource { URL, HTTPMethod, ReturnType }
/// 3) Make this class generic on the Resource
class APIRequest<ResponseType: Decodable>: NSObject {
    typealias STPAPIResponseBlock = (ResponseType?, HTTPURLResponse?, Error?) -> Void

    class func post(
        with apiClient: STPAPIClient,
        endpoint: String,
        additionalHeaders: [String: String] = [:],
        parameters: [String: Any],
        completion: @escaping STPAPIResponseBlock
    ) {
        // Build url
        let url = apiClient.apiURL.appendingPathComponent(endpoint)

        // Setup request
        let request = apiClient.configuredRequest(for: url, additionalHeaders: additionalHeaders)
        request.httpMethod = HTTPMethodPOST
        request.stp_setFormPayload(parameters)

        // Perform request
        apiClient.urlSession.stp_performDataTask(
            with: request as URLRequest,
            completionHandler: { body, response, error in
                self.parseResponse(response, body: body, error: error, completion: completion)
        })
    }

    class func getWith(
        _ apiClient: STPAPIClient,
        endpoint: String,
        parameters: [String: Any],
        completion: @escaping STPAPIResponseBlock
    ) {
        self.getWith(
            apiClient, endpoint: endpoint, additionalHeaders: [:], parameters: parameters,
            completion: completion)
    }

    class func getWith(
        _ apiClient: STPAPIClient,
        endpoint: String,
        additionalHeaders: [String: String],
        parameters: [String: Any],
        completion: @escaping STPAPIResponseBlock
    ) {
        // Build url
        let url = apiClient.apiURL.appendingPathComponent(endpoint)

        // Setup request
        let request = apiClient.configuredRequest(for: url, additionalHeaders: additionalHeaders)
        request.stp_addParameters(toURL: parameters)
        request.httpMethod = HTTPMethodGET

        // Perform request
        apiClient.urlSession.stp_performDataTask(
            with: request as URLRequest,
            completionHandler: { body, response, error in
                self.parseResponse(response, body: body, error: error, completion: completion)
        })
    }

    class func parseResponse<ResponseType: Decodable>(
        _ response: URLResponse?,
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
        if let body = body {
            do {
                let responseObject = try JSONDecoder().decode(ResponseType.self, from: body)
                safeCompletion(responseObject, nil)
            } catch(let error){
                safeCompletion(nil, error)
            }
        } else {
            safeCompletion(nil, RequestError.responseParsingError)
        }
    }
}

extension APIRequest {
    static func stpDispatchToMainThreadIfNecessary(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}

enum RequestError: Error {
    case responseParsingError
}
