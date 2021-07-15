//
//  StripeIdentityBundleLocator.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 7/13/21.
//

@_spi(STP) import StripeCore

final class StripeIdentityBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeIdentityBundleLocator.self
    static let bundleName = "StripeIdentity"
    static let resourcesBundle = StripeIdentityBundleLocator.computeResourcesBundle()
}
