//
//  Locale+StripeUICore.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public extension Locale {
    /// Returns the given array of country/region codes sorted alphabetically by their localized display names
    func sortedByTheirLocalizedNames<T: RegionCodeProvider>(
        _ regionCollection: [T],
        thisRegionFirst: Bool = false
    ) -> [T] {
        var mutableRegionCollection = regionCollection

        // Pull out the current country if needed
        var prepend: [T] = []
        if thisRegionFirst,
           let regionCode = self.stp_regionCode,
           let index = regionCollection.firstIndex(where: { $0.regionCode == regionCode }) {
            prepend = [mutableRegionCollection.remove(at: index)]
        }

        // Convert to display strings, sort, then map back to value
        mutableRegionCollection = mutableRegionCollection.map { (
            value: $0,
            display: localizedString(forRegionCode: $0.regionCode) ?? $0.regionCode
        ) }.sorted {
            $0.display.compare($1.display, options: [.diacriticInsensitive, .caseInsensitive], locale: self) == .orderedAscending
        }.map({
            $0.value
        })

        // Prepend current country if needed
        return prepend + mutableRegionCollection
    }
}
