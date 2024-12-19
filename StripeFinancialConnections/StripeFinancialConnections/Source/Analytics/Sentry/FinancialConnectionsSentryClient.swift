//
//  FinancialConnectionsSentryClient.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-10-22.
//

import Foundation
@_spi(STP) import StripeCore

protocol FinancialConnectionsErrorReporter {
    func report(error: Error, parameters: [String: Any])
}

class FinancialConnectionsSentryClient: FinancialConnectionsErrorReporter {
    private static let endpoint: URL = {
        let projectId = "871"
        var components = URLComponents()
        components.scheme = "https"
        components.host = "errors.stripe.com"
        components.path = "/api/\(projectId)/envelope/"
        return components.url!
    }()

    func report(error: Error, parameters: [String: Any]) {
        // TODO
    }
}
