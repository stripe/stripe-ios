//
//  NSMutableURLRequest+Stripe.swift
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

extension NSMutableURLRequest {
    func stp_addParameters(toURL parameters: [String: Any]) {
        guard let url = url else {
            assertionFailure()
            return
        }
        let urlString = url.absoluteString
        let query = STPFormEncoder.queryString(from: parameters)
        self.url = URL(string: urlString + (url.query != nil ? "&\(query)" : "?\(query)"))
    }

    func stp_setFormPayload(_ formPayload: [String: Any]) {
        let formData = STPFormEncoder.queryString(from: formPayload).data(using: .utf8)
        httpBody = formData
        setValue(
            String(format: "%lu", UInt(formData?.count ?? 0)), forHTTPHeaderField: "Content-Length")
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }

    func stp_setMultipartForm(_ data: Data?, boundary: String?) {
        httpBody = data
        setValue(
            String(format: "%lu", UInt(data?.count ?? 0)), forHTTPHeaderField: "Content-Length")
        setValue(
            "multipart/form-data; boundary=\(boundary ?? "")", forHTTPHeaderField: "Content-Type")
    }
}
