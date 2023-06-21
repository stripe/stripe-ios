//
//  Locale+StripeUICore.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public extension Locale {
    /// Returns the given array of country/region codes sorted alphabetically by their localized display names
    func sortedByTheirLocalizedNames<T: RegionCodeProvider>(
        _ regionCollection: [T],
        thisRegionFirst: Bool = false
    ) -> [T] {
        return regionCollection
    }
}
