//
//  StripeConnectionsBundleLocator.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/11/21.
//

import Foundation
@_spi(STP) import StripeCore

final class StripeConnectionsBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeConnectionsBundleLocator.self
    static let bundleName = "StripeConnections"
    #if SWIFT_PACKAGE
    static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeConnectionsBundleLocator.computeResourcesBundle()
}
