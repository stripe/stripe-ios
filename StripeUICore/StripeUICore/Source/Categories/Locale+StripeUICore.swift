//
//  Locale+StripeUICore.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/29/21.
//

import Foundation

@_spi(STP) public extension Locale {
    /// Returns the given array of country/region codes sorted alphabetically by their localized display names
    func sortedByTheirLocalizedNames(
        _ regionCodes: [String],
        thisRegionFirst: Bool = false
    ) -> [String] {
        var mutableCountryCodes = regionCodes

        // Pull out the current country if needed
        var prepend: [String] = []
        if thisRegionFirst,
           let regionCode = self.regionCode,
           let index = regionCodes.firstIndex(of: regionCode) {
            prepend = [mutableCountryCodes.remove(at: index)]
        }

        // Convert to display strings, sort, then map back to codes
        mutableCountryCodes = mutableCountryCodes.map { (
            code: $0,
            display: localizedString(forRegionCode: $0) ?? $0
        ) }.sorted {
            $0.display.compare($1.display, options: [.diacriticInsensitive, .caseInsensitive], locale: self) == .orderedAscending
        }.map({
            $0.code
        })

        // Prepend current country if needed
        return prepend + mutableCountryCodes
    }
}
