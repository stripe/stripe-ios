//
//  LinkConsumerIncentive.swift
//  StripeCore
//
//  Created by Till Hellmund on 1/10/25.
//

import Foundation

@_spi(STP) public struct LinkConsumerIncentive: Decodable {
    
    @_spi(STP) public let incentiveParams: IncentiveParams
    @_spi(STP) public let incentiveDisplayText: String?
    
    init(
        incentiveParams: IncentiveParams,
        incentiveDisplayText: String?
    ) {
        self.incentiveParams = incentiveParams
        self.incentiveDisplayText = incentiveDisplayText
    }
    
    @_spi(STP) public static func decodedObject(
        fromAPIResponse response: [AnyHashable : Any]?
    ) -> Self? {
        guard let response, let incentive = response["incentive_params"] as? [AnyHashable : Any] else {
            return nil
        }
        
        guard let paymentMethod = incentive["payment_method"] as? String else {
            return nil
        }
        
        let incentiveDisplayText = response["incentive_display_text"] as? String
        
        let incentiveParams = IncentiveParams(
            paymentMethod: paymentMethod
        )
        
        return LinkConsumerIncentive(
            incentiveParams: incentiveParams,
            incentiveDisplayText: incentiveDisplayText
        )
    }
    
    @_spi(STP) public struct IncentiveParams: Decodable {
        @_spi(STP) public let paymentMethod: String
    }
}
