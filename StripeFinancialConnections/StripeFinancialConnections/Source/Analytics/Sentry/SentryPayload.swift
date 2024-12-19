//
//  SentryPayload.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-10-22.
//

import Foundation
@_spi(STP) import StripeCore

struct SentryPayload: Encodable {
    let eventId: String = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    let timestamp: TimeInterval = Date().timeIntervalSince1970
    let release: String = StripeAPIConfiguration.STPSDKVersion
    let context: SentryContext = .shared
    let exception: SentryException
}
