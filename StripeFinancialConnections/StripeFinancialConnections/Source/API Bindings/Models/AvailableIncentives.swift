//
//  AvailableIncentives.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 12/17/24.
//

import Foundation

struct AvailableIncentives: Decodable {
    public let incentives: [LinkConsumerIncentive]
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        incentives = try container.decode([LinkConsumerIncentive].self, forKey: .data)
    }
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    // We don't care about the incentives, we just need to know that there are
    // *any* incentives.
    struct LinkConsumerIncentive: Decodable {}
}
