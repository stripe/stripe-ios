//
//  DeviceCanUseNativeLink.swift
//  StripeCore
//
//  Created by Mat Schmid on 2025-03-19.
//

import Foundation

/// Check if native Link is available on this device
@_spi(STP) public func deviceCanUseNativeLink(
    useAttestationEndpoints: Bool?,
    apiClient: STPAPIClient
) -> Bool {
    let useAttestationEndpoints = useAttestationEndpoints ?? false
    guard useAttestationEndpoints else {
        return false
    }

    // If we're in testmode, we don't need to attest for native Link
    if apiClient.isTestmode {
        return true
    }

    return apiClient.stripeAttest.isSupported
}
