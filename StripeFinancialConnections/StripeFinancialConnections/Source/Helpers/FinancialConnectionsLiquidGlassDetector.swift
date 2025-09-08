//
//  FinancialConnectionsLiquidGlassDetector.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 9/8/25.
//

import Foundation

class FinancialConnectionsLiquidGlassDetector {

    static var isEnabled: Bool {
        // If the app was built with Xcode 26 or later (which includes Swift compiler 6.2)...
        #if compiler(>=6.2)
        // And we're running on iOS 26 or later...
        if #available(iOS 26.0, *) {
            // And the app hasn't opted out of the new design...
            if !(Bundle.main.infoDictionary?["UIDesignRequiresCompatibility"] as? Bool ?? false) {
                // Then assume we're using the new design!
                return true
            }
        }
        #endif
        // Otherwise, use the old design
        return false
    }
}
