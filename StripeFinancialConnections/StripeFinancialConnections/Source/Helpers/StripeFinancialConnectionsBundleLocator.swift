//
//  StripeFinancialConnectionsBundleLocator.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/11/21.
//

import Foundation
@_spi(STP) import StripeCore

final class StripeFinancialConnectionsBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeFinancialConnectionsBundleLocator.self
    static let bundleName = "StripeFinancialConnectionsBundle"
    #if SWIFT_PACKAGE
    static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeFinancialConnectionsBundleLocator.computeResourcesBundle()
}
