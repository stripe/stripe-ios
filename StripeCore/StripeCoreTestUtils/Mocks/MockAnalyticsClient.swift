//
//  MockAnalyticsClient.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

@_spi(STP) public final class MockAnalyticsClient: STPAnalyticsClientProtocol {

    private(set) var productUsage: Set<String> = []
    private(set) var loggedAnalytics: [Analytic] = []

    public func addClass<T>(toProductUsageIfNecessary klass: T.Type) where T : STPAnalyticsProtocolSPI {
        productUsage.insert(klass.stp_analyticsIdentifierSPI)
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
