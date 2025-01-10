//
//  AvailableIncentives.swift
//  StripeCore
//
//  Created by Till Hellmund on 1/10/25.
//

import Foundation

@_spi(STP) public struct AvailableIncentives: Decodable {
    @_spi(STP) public  let incentives: [LinkConsumerIncentive]
    
    @_spi(STP) public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        incentives = try container.decode([LinkConsumerIncentive].self, forKey: .data)
    }
    
    enum CodingKeys: String, CodingKey {
        case data
    }
}
