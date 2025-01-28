//
//  ExperimentStore.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-28.
//

import Foundation

/// Internal store to access exoerimental features,
@_spi(STP) public class ExperimentStore {
    @_spi(STP) public static let shared = ExperimentStore()

    private init() {}

    @_spi(STP) public var useAsyncAPIClient: Bool = false
    @_spi(STP) public var supportsDynamicStyle: Bool = false
}
