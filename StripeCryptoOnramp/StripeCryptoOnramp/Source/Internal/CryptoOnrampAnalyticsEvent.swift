//
//  CryptoOnrampAnalyticsEvent.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 9/11/25.
//

import Foundation

enum CryptoOnrampOperation: String {
    case createSession = "configure"
    case hasLinkAccount = "has_link_account"
    case registerLinkUser = "register_link_user"
    case updatePhoneNumber = "update_phone_number"
    case authenticateUser = "authenticate_user"
    case authorize = "authorize"
    case attachKycInfo = "attach_kyc_info"
    case verifyIdentity = "verify_identity"
    case registerWalletAddress = "register_wallet_address"
    case collectPaymentMethod = "collect_payment_method"
    case createCryptoPaymentToken = "create_crypto_payment_token"
    case performCheckout = "perform_checkout"
    case logOut = "log_out"
}

enum CryptoOnrampAnalyticsEvent {
    case sessionCreated
    case linkAccountLookupCompleted(hasLinkAccount: Bool)
    case linkRegistrationCompleted
    case linkPhoneNumberUpdated
    case linkUserAuthenticationStarted
    case linkUserAuthenticationCompleted
    case linkAuthorizationStarted
    case linkAuthorizationCompleted(consented: Bool)
    case identityVerificationStarted
    case identityVerificationCompleted
    case kycInfoSubmitted
    case walletRegistered(network: String)
    case collectPaymentMethodStarted(paymentMethodType: String)
    case collectPaymentMethodCompleted(paymentMethodType: String)
    case cryptoPaymentTokenCreated(paymentMethodType: String)
    case checkoutStarted(onrampSessionId: String)
    case checkoutCompleted(onrampSessionId: String, requiredAction: Bool)
    case userLoggedOut
    case errorOccurred(during: CryptoOnrampOperation, errorMessage: String)

    var eventName: String {
        switch self {
        case .sessionCreated:
            return "onramp.session_created"
        case .linkAccountLookupCompleted:
            return "onramp.link_account_lookup_completed"
        case .linkRegistrationCompleted:
            return "onramp.link_registration_completed"
        case .linkPhoneNumberUpdated:
            return "onramp.link_phone_number_updated"
        case .linkUserAuthenticationStarted:
            return "onramp.link_user_authentication_started"
        case .linkUserAuthenticationCompleted:
            return "onramp.link_user_authentication_completed"
        case .linkAuthorizationStarted:
            return "onramp.link_authorization_started"
        case .linkAuthorizationCompleted:
            return "onramp.link_authorization_completed"
        case .identityVerificationStarted:
            return "onramp.identity_verification_started"
        case .identityVerificationCompleted:
            return "onramp.identity_verification_completed"
        case .kycInfoSubmitted:
            return "onramp.kyc_info_submitted"
        case .walletRegistered:
            return "onramp.wallet_registered"
        case .collectPaymentMethodStarted:
            return "onramp.collect_payment_method_started"
        case .collectPaymentMethodCompleted:
            return "onramp.collect_payment_method_completed"
        case .cryptoPaymentTokenCreated:
            return "onramp.crypto_payment_token_created"
        case .checkoutStarted:
            return "onramp.checkout_started"
        case .checkoutCompleted:
            return "onramp.checkout_completed"
        case .userLoggedOut:
            return "onramp.link_logout"
        case .errorOccurred:
            return "onramp.error_occurred"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .sessionCreated,
             .linkRegistrationCompleted,
             .linkPhoneNumberUpdated,
             .linkUserAuthenticationStarted,
             .linkUserAuthenticationCompleted,
             .linkAuthorizationStarted,
             .identityVerificationStarted,
             .identityVerificationCompleted,
             .kycInfoSubmitted,
             .userLoggedOut:
            return [:]
        case let .linkAccountLookupCompleted(hasLinkAccount):
            return ["has_link_account": hasLinkAccount]
        case let .linkAuthorizationCompleted(consented):
            return ["consented": consented]
        case let .walletRegistered(network):
            return ["network": network]
        case let .collectPaymentMethodStarted(paymentMethodType):
            return ["payment_method_type": paymentMethodType]
        case let .collectPaymentMethodCompleted(paymentMethodType):
            return ["payment_method_type": paymentMethodType]
        case let .cryptoPaymentTokenCreated(paymentMethodType):
            return ["payment_method_type": paymentMethodType]
        case let .checkoutStarted(onrampSessionId):
            return ["onramp_session_id": onrampSessionId]
        case let .checkoutCompleted(onrampSessionId, requiredAction):
            return [
                "onramp_session_id": onrampSessionId,
                "required_action": requiredAction,
            ]
        case let .errorOccurred(operationName, errorMessage):
            return [
                "operation_name": operationName.rawValue,
                "error_message": errorMessage,
            ]
        }
    }
}
