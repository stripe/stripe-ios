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
        let settings: LookupSettings?

        init(
            consumerSession: ConsumerSession,
            publishableKey: String,
            displayablePaymentDetails: DisplayablePaymentDetails? = nil,
            consentDataModel: LinkConsentDataModel? = nil,
            settings: LookupSettings? = nil
        ) {
            self.consumerSession = consumerSession
            self.publishableKey = publishableKey
            self.displayablePaymentDetails = displayablePaymentDetails
            self.consentDataModel = consentDataModel
            self.settings = settings
        }

        private enum CodingKeys: String, CodingKey {
            case consumerSession = "consumer_session"
            case publishableKey = "publishable_key"
            case displayablePaymentDetails = "displayable_payment_details"
            case consentDataModel = "consent_ui"
            case settings
        }
    }
}

extension ConsumerSession {
    final class DisplayablePaymentDetails: Decodable {
        enum PaymentType: String, Decodable, CaseIterable {
            case card = "CARD"
            case bankAccount = "BANK_ACCOUNT"
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

extension ConsumerSession {
    final class LookupSettings: Decodable {
        let emailOtpRequiresAdditionalInfo: Bool
        let emailOtpVerifyPhoneDespiteSmsOtp: Bool

        init(
            emailOtpRequiresAdditionalInfo: Bool = false,
            emailOtpVerifyPhoneDespiteSmsOtp: Bool = false
        ) {
            self.emailOtpRequiresAdditionalInfo = emailOtpRequiresAdditionalInfo
            self.emailOtpVerifyPhoneDespiteSmsOtp = emailOtpVerifyPhoneDespiteSmsOtp
        }

        private enum CodingKeys: String, CodingKey {
            case emailOtpRequiresAdditionalInfo = "email_otp_requires_additional_info"
            case emailOtpVerifyPhoneDespiteSmsOtp = "email_otp_verify_phone_despite_sms_otp"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.emailOtpRequiresAdditionalInfo = try container.decodeIfPresent(Bool.self, forKey: .emailOtpRequiresAdditionalInfo) ?? false
            self.emailOtpVerifyPhoneDespiteSmsOtp = try container.decodeIfPresent(Bool.self, forKey: .emailOtpVerifyPhoneDespiteSmsOtp) ?? false
        }
    }
}
