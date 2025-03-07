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

    enum Theme: String, SafeEnumCodable, Equatable {
        case light = "light"
        case dashboardLight = "dashboard_light"
        case linkLight = "link_light"
        case unparsable
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
    let appVerificationEnabled: Bool?
    let assignmentEventId: String?
    let businessName: String?
    let cancelUrl: String?
    let consentAcquiredAt: String?
    let consentRequired: Bool
    let customManualEntryHandling: Bool
    let disableLinkMoreAccounts: Bool
    let displayText: DisplayText?
    let experimentAssignments: [String: String]?
    let features: [String: Bool]?
    let hostedAuthUrl: String?
    let id: String
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
    let theme: Theme?

    var appearance: FinancialConnectionsAppearance {
        FinancialConnectionsAppearance(from: theme)
    }

    var shouldAttachLinkedPaymentMethod: Bool {
        return (paymentMethodType != nil)
    }

    var isProductInstantDebits: Bool {
        return (product == "instant_debits")
    }

    var isTestMode: Bool {
        !livemode
    }

    var verified: Bool {
        appVerificationEnabled ?? false
    }

    var consentAcquired: Bool {
        !consentRequired || (consentRequired && consentAcquiredAt != nil)
    }

    init(
        accountholderCustomerEmailAddress: String? = nil,
        accountholderIsLinkConsumer: Bool? = nil,
        accountholderPhoneNumber: String? = nil,
        accountholderToken: String? = nil,
        accountDisconnectionMethod: FinancialConnectionsSessionManifest.AccountDisconnectionMethod? = nil,
        activeAuthSession: FinancialConnectionsAuthSession? = nil,
        activeInstitution: FinancialConnectionsInstitution? = nil,
        allowManualEntry: Bool,
        appVerificationEnabled: Bool? = nil,
        assignmentEventId: String? = nil,
        businessName: String? = nil,
        cancelUrl: String? = nil,
        consentAcquiredAt: String? = nil,
        consentRequired: Bool,
        customManualEntryHandling: Bool,
        disableLinkMoreAccounts: Bool,
        displayText: FinancialConnectionsSessionManifest.DisplayText? = nil,
        experimentAssignments: [String: String]? = nil,
        features: [String: Bool]? = nil,
        hostedAuthUrl: String? = nil,
        id: String,
        initialInstitution: FinancialConnectionsInstitution? = nil,
        instantVerificationDisabled: Bool,
        institutionSearchDisabled: Bool,
        isEndUserFacing: Bool? = nil,
        isLinkWithStripe: Bool? = nil,
        isNetworkingUserFlow: Bool? = nil,
        isStripeDirect: Bool? = nil,
        livemode: Bool,
        manualEntryMode: FinancialConnectionsSessionManifest.ManualEntryMode,
        manualEntryUsesMicrodeposits: Bool,
        nextPane: FinancialConnectionsSessionManifest.NextPane,
        paymentMethodType: FinancialConnectionsPaymentMethodType? = nil,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
        product: String,
        singleAccount: Bool,
        skipSuccessPane: Bool? = nil,
        stepUpAuthenticationRequired: Bool? = nil,
        successUrl: String? = nil,
        theme: Theme? = nil
    ) {
        self.accountholderCustomerEmailAddress = accountholderCustomerEmailAddress
        self.accountholderIsLinkConsumer = accountholderIsLinkConsumer
        self.accountholderPhoneNumber = accountholderPhoneNumber
        self.accountholderToken = accountholderToken
        self.accountDisconnectionMethod = accountDisconnectionMethod
        self.activeAuthSession = activeAuthSession
        self.activeInstitution = activeInstitution
        self.allowManualEntry = allowManualEntry
        self.appVerificationEnabled = appVerificationEnabled
        self.assignmentEventId = assignmentEventId
        self.businessName = businessName
        self.cancelUrl = cancelUrl
        self.consentRequired = consentRequired
        self.consentAcquiredAt = consentAcquiredAt
        self.customManualEntryHandling = customManualEntryHandling
        self.disableLinkMoreAccounts = disableLinkMoreAccounts
        self.displayText = displayText
        self.experimentAssignments = experimentAssignments
        self.features = features
        self.hostedAuthUrl = hostedAuthUrl
        self.id = id
        self.initialInstitution = initialInstitution
        self.instantVerificationDisabled = instantVerificationDisabled
        self.institutionSearchDisabled = institutionSearchDisabled
        self.isEndUserFacing = isEndUserFacing
        self.isLinkWithStripe = isLinkWithStripe
        self.isNetworkingUserFlow = isNetworkingUserFlow
        self.isStripeDirect = isStripeDirect
        self.livemode = livemode
        self.manualEntryMode = manualEntryMode
        self.manualEntryUsesMicrodeposits = manualEntryUsesMicrodeposits
        self.nextPane = nextPane
        self.paymentMethodType = paymentMethodType
        self.permissions = permissions
        self.product = product
        self.singleAccount = singleAccount
        self.skipSuccessPane = skipSuccessPane
        self.stepUpAuthenticationRequired = stepUpAuthenticationRequired
        self.successUrl = successUrl
        self.theme = theme
    }
}
