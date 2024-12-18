//
//  AvailableIncentives.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 12/17/24.
//

import Foundation

struct AvailableIncentives: Decodable {
    public let hasAny: Bool
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode([LinkConsumerIncentive].self, forKey: .data)
        hasAny = !data.isEmpty
    }
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    // We don't care about the incentives, we just need to know that there are
    // *any* incentives.
    private struct LinkConsumerIncentive: Decodable {}
}
