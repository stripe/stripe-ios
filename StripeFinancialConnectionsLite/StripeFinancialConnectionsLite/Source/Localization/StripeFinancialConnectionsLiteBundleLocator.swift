//
//  StripeFinancialConnectionsLiteBundleLocator.swift
//  StripeFinancialConnectionsLite
//
//  Created by Mat Schmid on 6/20/25.
//

import Foundation
@_spi(STP) import StripeCore

final class StripeFinancialConnectionsLiteBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeFinancialConnectionsLiteBundleLocator.self
    static let bundleName = "StripeFinancialConnectionsLiteBundle"
    #if SWIFT_PACKAGE
        static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeFinancialConnectionsLiteBundleLocator.computeResourcesBundle()
}
