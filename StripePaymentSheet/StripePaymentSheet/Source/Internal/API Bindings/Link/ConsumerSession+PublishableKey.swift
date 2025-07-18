//
//  ConsumerSession+PublishableKey.swift
//  StripePaymentSheet
//
//  Created by Bill Meltsner on 2/7/23.
//  Copyright © 2023 Stripe, Inc. All rights reserved.
//

import Foundation

extension ConsumerSession {
    final class SessionWithPublishableKey: Decodable {
        let consumerSession: ConsumerSession
        let publishableKey: String
        let displayablePaymentDetails: DisplayablePaymentDetails?

        init(
            consumerSession: ConsumerSession,
            publishableKey: String,
            displayablePaymentDetails: DisplayablePaymentDetails? = nil
        ) {
            self.consumerSession = consumerSession
            self.publishableKey = publishableKey
            self.displayablePaymentDetails = displayablePaymentDetails
        }

        private enum CodingKeys: String, CodingKey {
            case consumerSession = "consumer_session"
            case publishableKey = "publishable_key"
            case displayablePaymentDetails = "displayable_payment_details"
        }
    }
}

extension ConsumerSession {
    final class DisplayablePaymentDetails: Decodable {
        let defaultCardBrand: String?
        let defaultPaymentType: String?
        let last4: String?
        let numberOfSavedPaymentDetails: Int?

        init(
            defaultCardBrand: String?,
            defaultPaymentType: String?,
            last4: String?,
            numberOfSavedPaymentDetails: Int?
        ) {
            self.defaultCardBrand = defaultCardBrand
            self.defaultPaymentType = defaultPaymentType
            self.last4 = last4
            self.numberOfSavedPaymentDetails = numberOfSavedPaymentDetails
        }

        private enum CodingKeys: String, CodingKey {
            case defaultCardBrand = "default_card_brand"
            case defaultPaymentType = "default_payment_type"
            case last4 = "last_4"
            case numberOfSavedPaymentDetails = "number_of_saved_payment_details"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.defaultCardBrand = try container.decodeIfPresent(String.self, forKey: .defaultCardBrand)
            self.defaultPaymentType = try container.decodeIfPresent(String.self, forKey: .defaultPaymentType)
            self.last4 = try container.decodeIfPresent(String.self, forKey: .last4)
            self.numberOfSavedPaymentDetails = try container.decodeIfPresent(Int.self, forKey: .numberOfSavedPaymentDetails)
        }
    }
}
