//
//  STPAnalyticsClient+StripeCoreTestingUtils.swift
//  StripeCoreTestUtils
//
//  Created by Yuki Tokuhiro on 11/4/23.
//

import Foundation
@_spi(STP) @testable import StripeCore

@_spi(STP) public class STPTestingAnalyticsClient: STPAnalyticsClient {
    public var events = [Analytic]()

    public override func log(analytic: Analytic, apiClient: STPAPIClient = .shared) {
        events.append(analytic)
        super.log(analytic: analytic)
    }
}
