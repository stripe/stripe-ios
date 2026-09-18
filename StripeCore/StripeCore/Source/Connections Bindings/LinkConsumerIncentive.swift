//
//  LinkConsumerIncentive.swift
//  StripeCore
//
//  Created by Till Hellmund on 1/10/25.
//

import Foundation

@_spi(STP) public struct LinkConsumerIncentive: Decodable {

    @_spi(STP) public let incentiveCampaign: String?
    @_spi(STP) public let incentiveParams: IncentiveParams
    @_spi(STP) public let incentiveDisplayText: String?
    @_spi(STP) public let incentiveParamsSignature: String?
    @_spi(STP) public let validForSession: Bool?

    init(
        incentiveCampaign: String? = nil,
        incentiveParams: IncentiveParams,
        incentiveDisplayText: String?,
        incentiveParamsSignature: String? = nil,
        validForSession: Bool? = nil
    ) {
        self.incentiveCampaign = incentiveCampaign
        self.incentiveParams = incentiveParams
        self.incentiveDisplayText = incentiveDisplayText
        self.incentiveParamsSignature = incentiveParamsSignature
        self.validForSession = validForSession
    }

    @_spi(STP) public static func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        guard let response, let incentive = response["incentive_params"] as? [AnyHashable: Any] else {
            return nil
        }

        guard let paymentMethod = incentive["payment_method"] as? String else {
            return nil
        }

        let incentiveCampaign = response["incentive_campaign"] as? String
        let incentiveDisplayText = response["incentive_display_text"] as? String
        let incentiveParamsSignature = response["incentive_params_signature"] as? String
        let validForSession = response["valid_for_session"] as? Bool

        let incentiveParams = IncentiveParams(
            paymentMethod: paymentMethod,
            amountFlat: incentive["amount_flat"] as? Int,
            amountPercent: incentive["amount_percent"] as? Double,
            currency: incentive["currency"] as? String,
            minimumPaymentAmount: incentive["minimum_payment_amount"] as? Int
        )

        return LinkConsumerIncentive(
            incentiveCampaign: incentiveCampaign,
            incentiveParams: incentiveParams,
            incentiveDisplayText: incentiveDisplayText,
            incentiveParamsSignature: incentiveParamsSignature,
            validForSession: validForSession
        )
    }

    @_spi(STP) public struct IncentiveParams: Decodable {
        @_spi(STP) public let paymentMethod: String
        @_spi(STP) public let amountFlat: Int?
        @_spi(STP) public let amountPercent: Double?
        @_spi(STP) public let currency: String?
        @_spi(STP) public let minimumPaymentAmount: Int?

        init(
            paymentMethod: String,
            amountFlat: Int? = nil,
            amountPercent: Double? = nil,
            currency: String? = nil,
            minimumPaymentAmount: Int? = nil
        ) {
            self.paymentMethod = paymentMethod
            self.amountFlat = amountFlat
            self.amountPercent = amountPercent
            self.currency = currency
            self.minimumPaymentAmount = minimumPaymentAmount
        }
    }
}
