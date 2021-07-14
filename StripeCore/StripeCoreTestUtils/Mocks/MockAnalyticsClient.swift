//
//  MockAnalyticsClient.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

@_spi(STP) public final class MockAnalyticsClient: STPAnalyticsClientProtocol {

    public private(set) var productUsage: Set<String> = []
    public private(set) var loggedAnalytics: [Analytic] = []

    public init() { }

    public func addClass<T>(toProductUsageIfNecessary klass: T.Type) where T : STPAnalyticsProtocol {
        productUsage.insert(klass.stp_analyticsIdentifier)
    }

    public func log(analytic: Analytic) {
        loggedAnalytics.append(analytic)
    }

    /// Clears `loggedAnalytics` and `productUsage`.
    public func reset() {
        productUsage = []
        loggedAnalytics = []
    }
}
