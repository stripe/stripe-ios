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
        let consentDataModel: LinkConsentDataModel?

        init(
            consumerSession: ConsumerSession,
            publishableKey: String,
            displayablePaymentDetails: DisplayablePaymentDetails? = nil,
            consentDataModel: LinkConsentDataModel? = nil
        ) {
            self.consumerSession = consumerSession
            self.publishableKey = publishableKey
            self.displayablePaymentDetails = displayablePaymentDetails
            self.consentDataModel = consentDataModel
        }

        private enum CodingKeys: String, CodingKey {
            case consumerSession = "consumer_session"
            case publishableKey = "publishable_key"
            case displayablePaymentDetails = "displayable_payment_details"
            case consentDataModel = "consent_ui"
        }
    }
}

extension ConsumerSession {
    final class DisplayablePaymentDetails: Decodable {
        enum PaymentType: String, SafeEnumDecodable, CaseIterable {
            case card = "CARD"
            case bankAccount = "BANK_ACCOUNT"
            case unparsable = ""
        }

        let defaultCardBrand: String?
        let defaultPaymentType: PaymentType?
        let last4: String?

        init(
            defaultCardBrand: String?,
            defaultPaymentType: PaymentType?,
            last4: String?
        ) {
            self.defaultCardBrand = defaultCardBrand
            self.defaultPaymentType = defaultPaymentType
            self.last4 = last4
        }

        private enum CodingKeys: String, CodingKey {
            case defaultCardBrand = "default_card_brand"
            case defaultPaymentType = "default_payment_type"
            case last4 = "last_4"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.defaultCardBrand = try container.decodeIfPresent(String.self, forKey: .defaultCardBrand)
            self.defaultPaymentType = try container.decodeIfPresent(PaymentType.self, forKey: .defaultPaymentType)
            self.last4 = try container.decodeIfPresent(String.self, forKey: .last4)
        }
    }
}
