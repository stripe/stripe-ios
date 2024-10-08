//
//  ConsumerFinancialIncentive.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 10/8/24.
//
import Foundation
@_spi(STP) import StripeCore

public extension StripeAPI {

    struct ConsumerFinancialIncentive {

        // MARK: - Types
        let eligible: Bool
        let incentiveAmount: Int?
    }
}

// MARK: - Decodable

@_spi(STP) extension StripeAPI.ConsumerFinancialIncentive: Decodable {}
