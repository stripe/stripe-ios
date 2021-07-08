//
//  STPAnalyticsProtocol.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
import Foundation

@_spi(STP) import StripeCore

/**
 Internal `StripeCore` implementation of `STPAnalyticsProtocolInternal`.

 - Note:
 NOTE(mludowise): This abstraction is necessary to avoid displaying
 `STPAnalyticsProtocol` conformance in our jazzy docs.
 If Jazzy ever provides the ability to ignore SPI-public protocol conformance,
 this should be removed.
 */
protocol STPAnalyticsProtocol: STPAnalyticsProtocolSPI {
    static var stp_analyticsIdentifier: String { get }
}

extension STPAnalyticsProtocol {
    /// :nodoc:
    @_spi(STP) public static var stp_analyticsIdentifierSPI: String {
        return stp_analyticsIdentifier
    }
}
