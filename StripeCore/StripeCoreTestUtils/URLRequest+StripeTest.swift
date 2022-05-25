//
//  URLRequest+StripeTest.swift
//  StripeiOS Tests
//
//  Created by David Estes on 9/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

public extension URLRequest {
    /// A Data representation of the response's body,
    /// fetched from the body Data or body InputStream.
    var httpBodyOrBodyStream: Data? {
        if let httpBody = httpBody {
            return httpBody
        }
        if let httpBodyStream = httpBodyStream {
            let maxLength = 1024
            var data = Data()
            var buffer = Data(count: maxLength)
            httpBodyStream.open()
                buffer.withUnsafeMutableBytes { bufferPtr in
                    let bufferTypedPtr = bufferPtr.bindMemory(to: UInt8.self)
                    while httpBodyStream.hasBytesAvailable {
                        let length = httpBodyStream.read(bufferTypedPtr.baseAddress!, maxLength: maxLength)
                        if length == 0 {
                            break
                        } else {
                            data.append(bufferTypedPtr.baseAddress!, count: length)
                        }
                    }
                }
            return data
        }
        return nil
    }
    
    // Query items sent as part of this URLRequest
    var queryItems: [URLQueryItem]? {
        let body = String(data: httpBodyOrBodyStream!, encoding: .utf8)!
        // Create a combined URLComponents with the URL params from the body
        var urlComponents = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        urlComponents?.query = body
        return urlComponents?.queryItems
    }
}

