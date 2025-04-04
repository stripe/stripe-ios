//
//  FinancialConnectionsAPIEndpoint.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-03-31.
//

import Foundation

enum FinancialConnectionsAPIEndpoint: String {
    // Link Account Sessions
    case listAccounts = "link_account_sessions/list_accounts"
    case attachPaymentAccount = "link_account_sessions/attach_payment_account"
    case sessionReceipt = "link_account_sessions/session_receipt"
    case consentAcquired = "link_account_sessions/consent_acquired"
    case linkMoreAccounts = "link_account_sessions/link_more_accounts"
    case complete = "link_account_sessions/complete"
    case selectInstitution = "link_account_sessions/institution_selected"

    // Connections
    case synchronize = "financial_connections/sessions/synchronize"
    case featuredInstitutions = "connections/featured_institutions"
    case searchInstitutions = "connections/institutions"
    case authSessions = "connections/auth_sessions"
    case authSessionsCancel = "connections/auth_sessions/cancel"
    case authSessionsRetrieve = "connections/auth_sessions/retrieve"
    case authSessionsOAuthResults = "connections/auth_sessions/oauth_results"
    case authSessionsAuthorized = "connections/auth_sessions/authorized"
    case authSessionsAccounts = "connections/auth_sessions/accounts"
    case authSessionsSelectedAccounts = "connections/auth_sessions/selected_accounts"
    case authSessionsEvents = "connections/auth_sessions/events"
    case authSessionsRepair = "connections/repair_sessions/generate_url"

    // Networking
    case disableNetworking = "link_account_sessions/disable_networking"
    case linkStepUpAuthenticationVerified = "link_account_sessions/link_step_up_authentication_verified"
    case linkVerified = "link_account_sessions/link_verified"
    case networkedAccounts = "link_account_sessions/networked_accounts"
    case saveAccountsToLink = "link_account_sessions/save_accounts_to_link"
    case shareNetworkedAccount = "link_account_sessions/share_networked_account"
    case consumerSessions = "connections/link_account_sessions/consumer_sessions"
    case pollAccountNumbers = "link_account_sessions/poll_account_numbers"

    // Instant Debits
    case startVerification = "consumers/sessions/start_verification"
    case confirmVerification = "consumers/sessions/confirm_verification"
    case linkAccountsSignUp = "consumers/accounts/sign_up"
    case attachLinkConsumerToLinkAccountSession = "consumers/attach_link_consumer_to_link_account_session"
    case paymentDetails = "consumers/payment_details"
    case sharePaymentDetails = "consumers/payment_details/share"
    case paymentMethods = "payment_methods"
    case availableIncentives = "consumers/incentives/update_available"

    // Verified
    case mobileConsumerSessionLookup = "consumers/mobile/sessions/lookup"
    case mobileLinkAccountSignup = "consumers/mobile/sign_up"

    /// As a rule of thumb, `shouldUseConsumerPublishableKey` should be `true` for requests that happen after the user is verified.
    /// However, there are some exceptions to this rules (such as the create payment method request).
    var shouldUseConsumerPublishableKey: Bool {
        switch self {
        case .attachPaymentAccount, .linkMoreAccounts, .complete, .synchronize,
             .featuredInstitutions, .searchInstitutions, .authSessions,
             .authSessionsCancel, .authSessionsRetrieve, .authSessionsOAuthResults,
             .authSessionsAuthorized, .authSessionsAccounts, .authSessionsSelectedAccounts,
             .authSessionsEvents, .networkedAccounts, .shareNetworkedAccount, .paymentDetails,
             .authSessionsRepair:
            return true
        case .listAccounts, .sessionReceipt, .consentAcquired, .disableNetworking,
             .linkStepUpAuthenticationVerified, .linkVerified, .saveAccountsToLink,
             .consumerSessions, .pollAccountNumbers, .startVerification, .confirmVerification,
             .linkAccountsSignUp, .attachLinkConsumerToLinkAccountSession,
             .sharePaymentDetails, .paymentMethods, .mobileLinkAccountSignup, .mobileConsumerSessionLookup,
             .availableIncentives, .selectInstitution:
            return false
        }
    }
}
