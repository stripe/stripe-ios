//
//  FeatureFlags.swift
//  StripeCore
//
//  Created by Till Hellmund on 4/26/25.
//

import Foundation

@_spi(STP) public enum FeatureFlags {
    // Add new features here to enable them in debug builds and disable them in release builds
    public static let linkPMsInSPM = FeatureFlag(name: "Link PMs in SPM", enabledInDebug: true)
}

@_spi(STP) public class FeatureFlag {
    public let name: String

    #if DEBUG
    public private(set) var isEnabled: Bool
    #else
    public let isEnabled: Bool = false
    #endif

    init(name: String, enabledInDebug: Bool) {
        self.name = name

        #if DEBUG
        isEnabled = enabledInDebug
        #endif
    }

    #if DEBUG
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    #endif
}
