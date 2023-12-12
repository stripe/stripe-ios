//
//  Locale+StripeCore.swift
//  StripeCore
//
//  Created by David Estes on 11/20/23.
//

import Foundation

@_spi(STP) public extension Locale {
    /// Returns the regionCode, for visionOS compatibility
    /// We can remove this once we drop iOS 16
    var stp_regionCode: String? {
#if canImport(CompositorServices)
        return self.region?.identifier
        #else
        return self.regionCode
        #endif
    }

    var stp_currencyCode: String? {
        #if canImport(CompositorServices)
        return self.currency?.identifier
        #else
        return self.currencyCode
        #endif
    }

    var stp_languageCode: String? {
#if canImport(CompositorServices)
        return self.language.languageCode?.identifier
        #else
        return self.languageCode
        #endif
    }

    static var stp_isoRegionCodes: [String] {
#if canImport(CompositorServices)
        return self.Region.isoRegions.map { $0.identifier }
#else
        return self.isoRegionCodes
#endif
    }
}
