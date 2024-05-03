//
//  STPAnalyticsClient+Error.swift
//  StripeCameraCore
//
//  Created by Yuki Tokuhiro on 3/18/24.
//

import Foundation

/// An error analytic that can be logged to our analytics system.
@_spi(STP) public struct ErrorAnalytic: Analytic {
    public let event: STPAnalyticEvent
    public let error: Error
    public var params: [String: Sendable] {
        var params = error.serializeForV1Analytics()
        params.mergeAssertingOnOverwrites(additionalNonPIIParams)
        return params
    }
    let additionalNonPIIParams: [String: Sendable]

    public init(event: STPAnalyticEvent, error: Error, additionalNonPIIParams: [String: Sendable] = [:]) {
        self.event = event
        self.error = error
        self.additionalNonPIIParams = additionalNonPIIParams
    }
}
