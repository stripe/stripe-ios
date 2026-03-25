//
//  AvailableIncentives.swift
//  StripeCore
//
//  Created by Till Hellmund on 1/10/25.
//

import Foundation

@_spi(STP) public struct AvailableIncentives: Decodable {
    @_spi(STP) public  let data: [LinkConsumerIncentive]
}
