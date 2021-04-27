//
//  MockAnalyticsClient.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@testable import Stripe

final class MockAnalyticsClient: STPAnalyticsClientProtocol {

    private(set) var productUsage: Set<String> = []
    private(set) var loggedAnalytics: [Analytic] = []

    func addClass<T>(toProductUsageIfNecessary klass: T.Type) where T : STPAnalyticsProtocol {
        productUsage.insert(klass.stp_analyticsIdentifier)
    }

    func log(analytic: Analytic) {
        loggedAnalytics.append(analytic)
    }

    /// Clears `loggedAnalytics` and `productUsage`.
    func reset() {
        productUsage = []
        loggedAnalytics = []
    }
}
