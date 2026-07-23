//
//  RequestBodyTestHelpers.swift
//  StripePaymentSheetTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeCore
import XCTest

enum RequestBodyTestHelpers {
    static func formEncodedBodyParams(
        from request: URLRequest,
        omittingEmptyValues: Bool = false,
        line: UInt = #line
    ) -> [String: String] {
        guard let httpBody = request.httpBodyOrBodyStream,
              let bodyString = String(data: httpBody, encoding: .utf8) else {
            XCTFail("Request body empty", line: line)
            return [:]
        }

        return bodyString.split(separator: "&").reduce(into: [:]) { params, pair in
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard let rawName = parts.first else { return }
            let rawValue = parts.count > 1 ? String(parts[1]) : ""
            guard !omittingEmptyValues || !rawValue.isEmpty else { return }

            let name = String(rawName).removingPercentEncoding ?? String(rawName)
            let value = rawValue.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? rawValue
            params[name] = value
        }
    }
}
