//
//  NSMutableURLRequest+Stripe.swift
//  StripeCore
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

extension URLRequest {
    @_spi(STP) public mutating func stp_addParameters(toURL parameters: [String: Any]) {
        guard let url else {
            assertionFailure()
            return
        }
        let query = URLEncoder.queryString(from: parameters)
        let urlString = url.absoluteString + (url.query != nil ? "&\(query)" : "?\(query)")
        // On iOS 17, the `URL` class initializers parse the string using the stricter RFC 3986 and started returning nil for certain URL strings we create, like "https://foo.com?foo[bar]=baz".
        // To preserve our old encoding behavior, we use CFURLCreateWithString instead.
        // It's possible that we could instead change our encoding behavior to use RFC 3986.
        // Seealso: https://jira.corp.stripe.com/browse/MOBILESDK-1335
        self.url = CFURLCreateWithString(nil, urlString as CFString, nil) as URL?
    }

    @_spi(STP) public mutating func stp_setFormPayload(_ formPayload: [String: Any]) {
        let formData = URLEncoder.queryString(from: formPayload).data(using: .utf8)
        httpBody = formData
        setValue(
            String(format: "%lu", UInt(formData?.count ?? 0)),
            forHTTPHeaderField: "Content-Length"
        )
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        #if DEBUG
        if StripeAPIConfiguration.includeDebugParamsHeader {
            setValue(URLEncoder.queryString(from: formPayload), forHTTPHeaderField: "X-Stripe-Mock-Request")
        }
        #endif
    }

    @_spi(STP) public mutating func stp_setMultipartForm(_ data: Data?, boundary: String?) {
        httpBody = data
        setValue(
            String(format: "%lu", UInt(data?.count ?? 0)),
            forHTTPHeaderField: "Content-Length"
        )
        setValue(
            "multipart/form-data; boundary=\(boundary ?? "")",
            forHTTPHeaderField: "Content-Type"
        )
    }
}
