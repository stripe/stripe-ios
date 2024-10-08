//
//  LinkConsumerIncentive.swift
//  StripePayments
//
//  Created by Till Hellmund on 10/8/24.
//

import Foundation

@_spi(STP) public final class LinkConsumerIncentive: NSObject, STPAPIResponseDecodable {
    
    @_spi(STP) public let campaign: String
    @_spi(STP) public let incentiveParams: IncentiveParams
    
    @_spi(STP) public let allResponseFields: [AnyHashable : Any]
    
    init(
        campaign: String,
        incentiveParams: IncentiveParams,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.campaign = campaign
        self.incentiveParams = incentiveParams
        self.allResponseFields = allResponseFields
    }
    
    @_spi(STP) public static func decodedObject(
        fromAPIResponse response: [AnyHashable : Any]?
    ) -> Self? {
        guard let response, let incentive = response["incentive_params"] as? [AnyHashable : Any] else {
            return nil
        }
        
        let campaign = response["campaign"] as! String
        
        let amountFlat = incentive["amount_flat"] as? Int
        let amountPercent = incentive["amount_percent"] as? Float
        let currency = incentive["currency"] as? String
        let paymentMethod = incentive["payment_method"] as? String
        
        guard let paymentMethod else {
            return nil
        }
        
        let incentiveParams = IncentiveParams(
            amountFlat: amountFlat,
            amountPercent: amountPercent,
            currency: currency,
            paymentMethod: paymentMethod
        )
        
        return LinkConsumerIncentive(
            campaign: campaign,
            incentiveParams: incentiveParams,
            allResponseFields: response
        ) as? Self
    }
    
    @_spi(STP) public struct IncentiveParams {
        @_spi(STP) public let amountFlat: Int?
        @_spi(STP) public let amountPercent: Float?
        @_spi(STP) public let currency: String?
        @_spi(STP) public let paymentMethod: String
    }
}
