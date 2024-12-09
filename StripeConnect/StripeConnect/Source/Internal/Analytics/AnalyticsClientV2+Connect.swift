//
//  AnalyticsClientV2+Connect.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

import Foundation
@_spi(STP) import StripeCore

extension AnalyticsClientV2 {
    static let sharedConnect = AnalyticsClientV2(
        clientId: "mobile_connect_sdk",
        origin: "stripe-connect-ios"
    )
}
