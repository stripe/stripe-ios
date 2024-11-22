//
//  APIError.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/23/24.
//

import Foundation

enum APIError: Error, CustomDebugStringConvertible {
    case failedToParse(error: Error)
    case invalidURL
    case networkError(error: Error)
    case responseError(response: APIErrorResponse)
    case unknown(error: Error)

    var debugDescription: String {
        switch self {
        case let .failedToParse(error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid url"
        case let .responseError(response):
            return response.error
        case let .networkError(error):
            return "Network Error: \(error.localizedDescription)"
        case let .unknown(error):
            return "An unknown error occurred: \(error)"
        }
    }
}

struct APIErrorResponse: Codable {
    let error: String
}
