//
//  AvailableIncentives.swift
//  StripeCore
//
//  Created by Till Hellmund on 1/10/25.
//

import Foundation

@_spi(InternalOnlyAPI) public struct AvailableIncentives: Decodable {
    @_spi(InternalOnlyAPI) public  let data: [LinkConsumerIncentive]
}
