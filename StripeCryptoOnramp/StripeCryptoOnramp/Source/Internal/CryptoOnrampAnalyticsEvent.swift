//
//  CryptoOnrampAnalyticsEvent.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 9/11/25.
//

import Foundation

enum CryptoOnrampAnalyticsEvent {
    case sessionCreated
    case linkRegistrationCompleted
    case linkVerificationStarted
    case linkVerificationCompleted
    case linkAuthorizationStarted
    case linkAuthorizationCompleted(consented: Bool)
    case identityVerificationStarted
    case identityVerificationCompleted
    case kycInfoSubmitted
    case walletRegistered(network: String)
    case collectPaymentMethodStarted(paymentMethodType: String)
    case collectPaymentMethodCompleted(paymentMethodType: String)
    case cryptoPaymentTokenCreated(paymentMethodType: String)
    case checkoutStarted(onrampSessionId: String, paymentMethodType: String)
    case checkoutCompleted(onrampSessionId: String, paymentMethodType: String, requiredAction: Bool)
    case errorOccurred(operationName: String, errorType: String?)

    var eventName: String {
        switch self {
        case .sessionCreated:
            return "onramp.session_created"
        case .linkRegistrationCompleted:
            return "onramp.link_registration_completed"
        case .linkVerificationStarted:
            return "onramp.link_verification_started"
        case .linkVerificationCompleted:
            return "onramp.link_verification_completed"
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
        case .errorOccurred:
            return "onramp.error_occured"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .sessionCreated,
             .linkRegistrationCompleted,
             .linkVerificationStarted,
             .linkVerificationCompleted,
             .linkAuthorizationStarted,
             .identityVerificationStarted,
             .identityVerificationCompleted,
             .kycInfoSubmitted:
            return [:]
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
        case let .checkoutStarted(onrampSessionId, paymentMethodType):
            return [
                "onramp_session_id": onrampSessionId,
                "payment_method_type": paymentMethodType,
            ]
        case let .checkoutCompleted(onrampSessionId, paymentMethodType, requiredAction):
            return [
                "onramp_session_id": onrampSessionId,
                "payment_method_type": paymentMethodType,
                "required_action": requiredAction,
            ]
        case let .errorOccurred(operationName, errorType):
            var params: [String: Any] = ["operation_name": operationName]
            if let errorType = errorType {
                params["error_type"] = errorType
            }
            return params
        }
    }
}
