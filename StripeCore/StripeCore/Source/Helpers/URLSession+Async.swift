//
//  URLSession+Async.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 1/6/23.
//

import Foundation

@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
extension URLSession {
    /// An Xcode 13 compatible version of `data(for:)`
    /// Taken from https://www.swiftbysundell.com/articles/making-async-system-apis-backward-compatible/
    @_spi(STP) public func stp_data(for request: URLRequest) async throws -> (Data, URLResponse) {
         try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                 guard let data = data, let response = response else {
                     let error = error ?? URLError(.badServerResponse)
                     return continuation.resume(throwing: error)
                 }
                 continuation.resume(returning: (data, response))
             }
             task.resume()
        }
    }
}
