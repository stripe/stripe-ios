//
// FinancialConnectionsSessionManifest.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

struct FinancialConnectionsSessionManifest: Decodable {

    // MARK: - Types

    enum NextPane: String, SafeEnumCodable, Equatable {
        case accountPicker = "account_picker"
        case attachLinkedPaymentAccount = "attach_linked_payment_account"
        case authOptions = "auth_options"
        case consent = "consent"
        case institutionPicker = "institution_picker"
        case linkAccountPicker = "link_account_picker"
        case linkConsent = "link_consent"
        case linkLogin = "link_login"
        case manualEntry = "manual_entry"
        case manualEntrySuccess = "manual_entry_success"
        case networkingLinkLoginWarmup = "networking_link_login_warmup"
        case networkingLinkSignupPane = "networking_link_signup_pane"
        case networkingLinkVerification = "networking_link_verification"
        case partnerAuth = "partner_auth"
        case success = "success"
        case unexpectedError = "unexpected_error"
        case unparsable

        // client-side only panes
        case resetFlow = "reset_flow"
        case terminalError = "terminal_error"
    }

    enum AccountDisconnectionMethod: String, SafeEnumCodable, Equatable {
        case dashboard
        case support
        case email
        case link
        case unparsable
    }

    enum ManualEntryMode: String, SafeEnumCodable, Equatable {
        case automatic
        case custom
        case unparsable
    }

    // MARK: - Properties

    let accountholderIsLinkConsumer: Bool?
    let activeInstitution: FinancialConnectionsInstitution?
    let allowManualEntry: Bool
    let businessName: String?
    let consentRequired: Bool
    let customManualEntryHandling: Bool
    let disableLinkMoreAccounts: Bool
    let hostedAuthUrl: String?
    let successUrl: String?
    let cancelUrl: String?
    let activeAuthSession: FinancialConnectionsAuthSession?
    let initialInstitution: FinancialConnectionsInstitution?
    let instantVerificationDisabled: Bool
    let institutionSearchDisabled: Bool
    let isLinkWithStripe: Bool?
    let isNetworkingUserFlow: Bool?
    let isStripeDirect: Bool?
    let livemode: Bool
    let manualEntryUsesMicrodeposits: Bool
    let nextPane: NextPane
    let permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]
    let singleAccount: Bool
    let paymentMethodType: FinancialConnectionsPaymentMethodType?
    let accountDisconnectionMethod: AccountDisconnectionMethod?
    let isEndUserFacing: Bool?
    let product: String
    let accountholderToken: String?
    let features: [String: Bool]?
    let experimentAssignments: [String: String]?
    let assignmentEventId: String?
    let skipSuccessPane: Bool?
    let manualEntryMode: ManualEntryMode
    let accountholderCustomerEmailAddress: String?
}
