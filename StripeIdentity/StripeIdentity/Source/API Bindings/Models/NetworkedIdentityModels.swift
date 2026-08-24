//
//  NetworkedIdentityModels.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

enum NetworkedIdentityVerificationType: String, Equatable {
    case sms = "SMS"
    case email = "EMAIL"
}

enum NetworkedIdentityCountryInferringMethod: String, Equatable {
    case phoneNumber = "PHONE_NUMBER"
    case defaultUS = "DEFAULT_US"
    case unknown = "UNKNOWN"
}

enum NetworkedIdentityVerificationSessionState: String, SafeEnumDecodable, Equatable {
    case started = "STARTED"
    case failed = "FAILED"
    case verified = "VERIFIED"
    case canceled = "CANCELED"
    case expired = "EXPIRED"
    case invalid = "VERIFICATION_STATE_INVALID"
    case unparsable
}

enum NetworkedIdentityVerificationSessionType: String, SafeEnumDecodable, Equatable {
    case email = "EMAIL"
    case sms = "SMS"
    case webAuthn = "WEBAUTHN"
    case admin = "ADMIN"
    case signUp = "SIGNUP"
    case supportTier1 = "SUPPORT_TIER_1"
    case invalid = "VERIFICATION_TYPE_INVALID"
    case unparsable
}

struct NetworkedIdentityVerificationSession: Decodable, Equatable {
    let id: String?
    let state: NetworkedIdentityVerificationSessionState
    let type: NetworkedIdentityVerificationSessionType
    let verificationToken: String?
}

struct NetworkedIdentityConsumerSession: Decodable, Equatable {
    let clientSecret: String
    let emailAddress: String
    let redactedPhoneNumber: String
    let redactedFormattedPhoneNumber: String
    let unredactedPhoneNumber: String?
    let phoneNumberCountry: String?
    let verificationSessions: [NetworkedIdentityVerificationSession]
}

struct NetworkedIdentityExperiment: Decodable, Equatable {
    let experimentName: String
    let variant: String
    let responseID: String?

    private enum CodingKeys: String, CodingKey {
        case experimentName
        case variant
        case responseID = "response_id"
    }
}

enum NetworkedIdentityLookupResponse: Decodable, Equatable {
    case found(NetworkedIdentityLookupFoundResponse)
    case notFound(NetworkedIdentityLookupNotFoundResponse)

    private enum CodingKeys: String, CodingKey {
        case exists
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if try container.decode(Bool.self, forKey: .exists) {
            self = .found(try NetworkedIdentityLookupFoundResponse(from: decoder))
        } else {
            self = .notFound(try NetworkedIdentityLookupNotFoundResponse(from: decoder))
        }
    }
}

struct NetworkedIdentityLookupFoundResponse: Decodable, Equatable {
    let consumerSession: NetworkedIdentityConsumerSession
    let publishableKey: String
    let accountID: String?
    let authSessionClientSecret: String?
    let emailOTPRequiresAdditionalInfo: Bool?
    let emailOTPVerifyPhoneDespiteSMSOTP: Bool?
    let experiments: [NetworkedIdentityExperiment]

    private enum CodingKeys: String, CodingKey {
        case consumerSession
        case publishableKey
        case accountID = "account_id"
        case authSessionClientSecret
        case emailOTPRequiresAdditionalInfo = "email_otp_requires_additional_info"
        case emailOTPVerifyPhoneDespiteSMSOTP = "email_otp_verify_phone_despite_sms_otp"
        case experiments
    }
}

struct NetworkedIdentityLookupNotFoundResponse: Decodable, Equatable {
    let errorMessage: String
}

struct NetworkedIdentityConsumerSessionResponse: Decodable, Equatable {
    let consumerSession: NetworkedIdentityConsumerSession
    let authSessionClientSecret: String?
}

struct NetworkedIdentitySignUpResponse: Decodable, Equatable {
    let publishableKey: String
    let accountID: String
    let authSessionClientSecret: String?
    let consumerSession: NetworkedIdentityConsumerSession

    private enum CodingKeys: String, CodingKey {
        case publishableKey
        case accountID = "account_id"
        case authSessionClientSecret
        case consumerSession
    }
}

enum NetworkedIdentityDocumentType: String, SafeEnumDecodable, Equatable {
    case passport
    case drivingLicense = "driving_license"
    case idCard = "id_card"
    case unparsable
}

struct NetworkedIdentityDocument: Decodable, Equatable {
    let id: String
    let documentType: NetworkedIdentityDocumentType
    let created: Int
    let country: String?
    let region: String?
    let redactedDocumentNumber: String?
    let expirationDate: Int?
    let liveCaptured: Bool?
}

struct NetworkedIdentityDocumentListResponse: Decodable, Equatable {
    let data: [NetworkedIdentityDocument]
}

struct NetworkedIdentityAssociationTokenResponse: Decodable, Equatable {
    let associationToken: String
}

struct NetworkedIdentityExtendSessionResponse: Decodable, Equatable {
    let consumerSessionClientSecret: String?
}

struct NetworkedIdentitySignUpRequest: Equatable {
    let emailAddress: String
    let phoneNumber: String
    let country: String
    let countryInferringMethod: NetworkedIdentityCountryInferringMethod
    let locale: String
    let defaultOptInEnabled: Bool?
    let changedPhoneNumber: Bool?
    let checkedOptInBox: Bool?
    let legalName: String?
    let hcaptchaResponse: String?
    let hcaptchaKey: String?
    let sessionID: String?
    let verificationSessionClientSecrets: [String]?

    init(
        emailAddress: String,
        phoneNumber: String,
        country: String,
        countryInferringMethod: NetworkedIdentityCountryInferringMethod,
        locale: String,
        defaultOptInEnabled: Bool? = nil,
        changedPhoneNumber: Bool? = nil,
        checkedOptInBox: Bool? = nil,
        legalName: String? = nil,
        hcaptchaResponse: String? = nil,
        hcaptchaKey: String? = nil,
        sessionID: String? = nil,
        verificationSessionClientSecrets: [String]? = nil
    ) {
        self.emailAddress = emailAddress
        self.phoneNumber = phoneNumber
        self.country = country
        self.countryInferringMethod = countryInferringMethod
        self.locale = locale
        self.defaultOptInEnabled = defaultOptInEnabled
        self.changedPhoneNumber = changedPhoneNumber
        self.checkedOptInBox = checkedOptInBox
        self.legalName = legalName
        self.hcaptchaResponse = hcaptchaResponse
        self.hcaptchaKey = hcaptchaKey
        self.sessionID = sessionID
        self.verificationSessionClientSecrets = verificationSessionClientSecrets
    }
}

struct NetworkedIdentityStartVerificationRequest: Equatable {
    let consumerSessionClientSecret: String
    let type: NetworkedIdentityVerificationType
    let locale: String?
    let accountPhoneNumber: String?
    let verificationSessionClientSecrets: [String]?

    init(
        consumerSessionClientSecret: String,
        type: NetworkedIdentityVerificationType = .sms,
        locale: String? = nil,
        accountPhoneNumber: String? = nil,
        verificationSessionClientSecrets: [String]? = nil
    ) {
        self.consumerSessionClientSecret = consumerSessionClientSecret
        self.type = type
        self.locale = locale
        self.accountPhoneNumber = accountPhoneNumber
        self.verificationSessionClientSecrets = verificationSessionClientSecrets
    }
}

struct NetworkedIdentityConfirmVerificationRequest: Equatable {
    let consumerSessionClientSecret: String
    let code: String
    let type: NetworkedIdentityVerificationType
    let verificationSessionClientSecrets: [String]?

    init(
        consumerSessionClientSecret: String,
        code: String,
        type: NetworkedIdentityVerificationType = .sms,
        verificationSessionClientSecrets: [String]? = nil
    ) {
        self.consumerSessionClientSecret = consumerSessionClientSecret
        self.code = code
        self.type = type
        self.verificationSessionClientSecrets = verificationSessionClientSecrets
    }
}
