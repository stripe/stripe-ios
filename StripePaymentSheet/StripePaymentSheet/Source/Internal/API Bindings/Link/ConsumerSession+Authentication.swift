// Copyright © 2026 Stripe, Inc. All rights reserved.

import Foundation
@_spi(STP) import StripeCore

extension ConsumerSession {
    struct VerificationFactor: Decodable, Equatable {
        enum FactorType: String, SafeEnumDecodable {
            case sms = "SMS"
            case email = "EMAIL"
            case unparsable

            var verificationType: SupportedVerificationType? {
                SupportedVerificationType(rawValue: rawValue)
            }
        }

        let type: FactorType
        let providesFurtherVerification: Bool
        let temporarilyDisabled: Bool
        let id: String?

        var isStartable: Bool {
            !temporarilyDisabled && providesFurtherVerification
        }
    }

    struct LookupSettings: Decodable {
        /// Lookup-only UX hint. Start-verification enforces the current requirement.
        let emailOtpRequiresAdditionalInfo: Bool?

        private enum CodingKeys: String, CodingKey {
            case emailOtpRequiresAdditionalInfo = "email_otp_requires_additional_info"
        }
    }

    struct AuthResponse: Decodable {
        let consumerSession: ConsumerSession
        let verificationSessionId: String?
        let settings: LookupSettings?
        let linkBrand: LinkBrand?

        init(consumerSession: ConsumerSession, verificationSessionId: String? = nil, settings: LookupSettings? = nil, linkBrand: LinkBrand? = nil) {
            self.consumerSession = consumerSession
            self.verificationSessionId = verificationSessionId
            self.settings = settings
            self.linkBrand = linkBrand
        }

        private enum CodingKeys: String, CodingKey {
            case consumerSession = "consumer_session"
            case verificationSessionId = "verification_session_id"
            case settings
            case linkBrand = "link_brand"
        }
    }
}
