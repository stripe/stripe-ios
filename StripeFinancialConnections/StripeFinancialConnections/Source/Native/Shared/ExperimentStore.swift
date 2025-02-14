//
//  ExperimentStore.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-28.
//

import Foundation

/// Internal singleton store to access experimental features.
/// Enabling any of these might result in unexpected behavior.
@_spi(STP) public class ExperimentStore {
    @_spi(STP) public static let shared = ExperimentStore()

    private init() {}

    @_spi(STP) public var useAsyncAPIClient: Bool = false

    @_spi(STP) public func reset() {
        useAsyncAPIClient = false
    }
}
