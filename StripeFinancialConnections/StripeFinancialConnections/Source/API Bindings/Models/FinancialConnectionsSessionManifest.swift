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
        case bankAuthRepair = "bank_auth_repair"
        case consent = "consent"
        case institutionPicker = "institution_picker"
        case linkAccountPicker = "link_account_picker"
        case linkConsent = "link_consent"
        case linkLogin = "link_login"
        case manualEntry = "manual_entry"
        case manualEntrySuccess = "manual_entry_success"
        case networkingLinkLoginWarmup = "networking_link_login_warmup"
        case networkingLinkSignupPane = "networking_link_signup_pane"
        case networkingLinkStepUpVerification = "networking_link_step_up_verification"
        case networkingLinkVerification = "networking_link_verification"
        case networkingSaveToLinkVerification = "networking_save_to_link_verification"
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

    struct DisplayText: Decodable {
        let successPane: SuccessPane?

        struct SuccessPane: Decodable {
            let subCaption: String?
        }
    }

    // MARK: - Properties

    let accountholderCustomerEmailAddress: String?
    let accountholderIsLinkConsumer: Bool?
    let accountholderPhoneNumber: String?
    let accountholderToken: String?
    let accountDisconnectionMethod: AccountDisconnectionMethod?
    let activeAuthSession: FinancialConnectionsAuthSession?
    let activeInstitution: FinancialConnectionsInstitution?
    let allowManualEntry: Bool
    let assignmentEventId: String?
    let businessName: String?
    let cancelUrl: String?
    let consentRequired: Bool
    let customManualEntryHandling: Bool
    let disableLinkMoreAccounts: Bool
    let displayText: DisplayText?
    let experimentAssignments: [String: String]?
    let features: [String: Bool]?
    let hostedAuthUrl: String?
    let initialInstitution: FinancialConnectionsInstitution?
    let instantVerificationDisabled: Bool
    let institutionSearchDisabled: Bool
    let isEndUserFacing: Bool?
    let isLinkWithStripe: Bool?
    let isNetworkingUserFlow: Bool?
    let isStripeDirect: Bool?
    let livemode: Bool
    let manualEntryMode: ManualEntryMode
    let manualEntryUsesMicrodeposits: Bool
    let nextPane: NextPane
    let paymentMethodType: FinancialConnectionsPaymentMethodType?
    let permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]
    let product: String
    let singleAccount: Bool
    let skipSuccessPane: Bool?
    let stepUpAuthenticationRequired: Bool?
    let successUrl: String?
    let theme: FinancialConnectionsTheme?

    var shouldAttachLinkedPaymentMethod: Bool {
        return (paymentMethodType != nil)
    }

    var isProductInstantDebits: Bool {
        return (product == "instant_debits")
    }

    var isTestMode: Bool {
        !livemode
    }
}
