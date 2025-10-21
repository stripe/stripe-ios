//
//  LinkInlineSignupViewModel.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/19/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

protocol LinkInlineSignupViewModelDelegate: AnyObject {
    func signupViewModelDidUpdate(_ viewModel: LinkInlineSignupViewModel)
}

final class LinkInlineSignupViewModel {
    enum Action: Equatable {
        case signupAndPay(account: PaymentSheetLinkAccount, phoneNumber: PhoneNumber?, legalName: String?)
        case continueWithoutLink
    }

    enum Mode {
        case checkbox // shows the Link inline signup with the checkbox and nested form fields
        case checkboxWithDefaultOptIn // shows the Link inline signup with a pre-checked checkbox and a label showing the used signup data
        case textFieldsOnlyEmailFirst // shows the Link inline signup without the checkbox, email field first
        case textFieldsOnlyPhoneFirst // shows the Link inline signup without the checkbox, phone number field first
        case signupOptIn // shows the Link signup opt-in with a checkbox
    }

    weak var delegate: LinkInlineSignupViewModelDelegate?

    private let accountService: LinkAccountServiceProtocol

    let analyticsHelper: PaymentSheetAnalyticsHelper?

    private let accountLookupDebouncer = OperationDebouncer(debounceTime: LinkUI.accountLookupDebounceTime)

    private let country: String?

    let configuration: PaymentElementConfiguration

    let mode: Mode

    var saveCheckboxChecked: Bool = false {
        didSet {
            if saveCheckboxChecked != oldValue {
                didInteractWithSaveCheckbox = true
                notifyUpdate()

                if saveCheckboxChecked, mode == .checkbox {
                    STPAnalyticsClient.sharedClient.logLinkSignupCheckboxChecked()
                }
            }
        }
    }

    private var didInteractWithSaveCheckbox = false

    var emailAddress: String? {
        didSet {
            if emailAddress != oldValue {
                onEmailUpdate()
            }
        }
    }

    var legalName: String? {
        didSet {
            if legalName != oldValue {
                notifyUpdate()
            }
        }
    }

    var phoneNumber: PhoneNumber? {
        didSet {
            if phoneNumber != oldValue {
                notifyUpdate()
            }
        }
    }
    var phoneNumberWasPrefilled: Bool = false
    var emailWasPrefilled: Bool = false
    var didAskToChangeSignupData: Bool = false

    private var defaultOptInInfoWasPrefilled: Bool {
        emailWasPrefilled && phoneNumberWasPrefilled
    }

    var consentAction: PaymentSheetLinkAccount.ConsentAction {
        switch mode {
        case .checkbox:
            if phoneNumberWasPrefilled && emailWasPrefilled {
                return .checkbox_v0_1
            } else if emailWasPrefilled {
                return .checkbox_v0_0
            } else {
                return .checkbox_v0
            }
        case .checkboxWithDefaultOptIn:
            if phoneNumberWasPrefilled && emailWasPrefilled {
                return .prechecked_opt_in_box_prefilled_all
            } else if phoneNumberWasPrefilled || emailWasPrefilled {
                return .prechecked_opt_in_box_prefilled_some
            } else {
                return .prechecked_opt_in_box_prefilled_none
            }
        case .textFieldsOnlyEmailFirst:
            return .implied_v0
        case .textFieldsOnlyPhoneFirst:
            return .implied_v0_0
        case .signupOptIn:
            if didInteractWithSaveCheckbox {
                return .sign_up_opt_in_mobile_checked
            } else {
                return .sign_up_opt_in_mobile_prechecked
            }
        }
    }

    private(set) var linkAccount: PaymentSheetLinkAccount? {
        didSet {
            if linkAccount !== oldValue {
                notifyUpdate()

                if let linkAccount = linkAccount,
                   !linkAccount.isRegistered {
                        STPAnalyticsClient.sharedClient.logLinkSignupStart()
                }
            }
        }
    }

    private(set) var isLookingUpLinkAccount: Bool = false {
        didSet {
            if isLookingUpLinkAccount != oldValue {
                notifyUpdate()
            }
        }
    }

    private(set) var lookupFailed: Bool = false {
        didSet {
            if lookupFailed != oldValue {
                notifyUpdate()
            }
        }
    }

    var useLiquidGlass: Bool {
        configuration.appearance.cornerRadius == nil && LiquidGlassDetector.isEnabledInMerchantApp
    }

    var requiresNameCollection: Bool {
        return country != "US"
    }

    var legalNameProvided: Bool {
        guard let legalName = legalName else {
            return false
        }

        return !legalName.isBlank
    }

    var requiresPhoneNumberCollection: Bool {
        return linkAccount?.sessionState == .requiresSignUp
    }

    var phoneNumberProvided: Bool {
        guard let phoneNumber = phoneNumber else {
            return false
        }

        return phoneNumber.isComplete
    }

    var shouldShowEmailField: Bool {
        switch mode {
        case .checkbox:
            return saveCheckboxChecked
        case .checkboxWithDefaultOptIn:
            return saveCheckboxChecked && (!defaultOptInInfoWasPrefilled || didAskToChangeSignupData)
        case .textFieldsOnlyEmailFirst:
            return true
        case .textFieldsOnlyPhoneFirst:
            // Only show email if the phone number field has contents
            return (phoneNumber?.isComplete ?? false)
        case .signupOptIn:
            return false
        }
    }

    var shouldShowNameField: Bool {
        switch mode {
        case .checkbox, .textFieldsOnlyEmailFirst:
            guard saveCheckboxChecked,
                  let linkAccount = linkAccount else {
                return false
            }
            return !linkAccount.isRegistered && requiresNameCollection
        case .checkboxWithDefaultOptIn:
            return false
        case .textFieldsOnlyPhoneFirst:
            return requiresNameCollection && phoneNumber?.isComplete ?? false
        case .signupOptIn:
            return false
        }
    }

    var shouldShowPhoneField: Bool {
        switch mode {
        case .checkbox, .textFieldsOnlyEmailFirst:
            guard saveCheckboxChecked,
                  let linkAccount = linkAccount
            else {
                return false
            }

            return !linkAccount.isRegistered
        case .checkboxWithDefaultOptIn:
            let isExistingConsumer = linkAccount?.isRegistered ?? false
            return saveCheckboxChecked && (!defaultOptInInfoWasPrefilled || didAskToChangeSignupData) && !isExistingConsumer
        case .textFieldsOnlyPhoneFirst:
            return true
        case .signupOptIn:
            return false
        }
    }

    var shouldShowLegalTerms: Bool {
        switch mode {
        case .checkbox:
            return saveCheckboxChecked
        case .checkboxWithDefaultOptIn:
            return saveCheckboxChecked
        case .textFieldsOnlyPhoneFirst, .textFieldsOnlyEmailFirst:
            return true
        case .signupOptIn:
            return false
        }
    }

    var shouldShowDefaultOptInView: Bool {
        guard mode == .checkboxWithDefaultOptIn else {
            return false
        }
        return saveCheckboxChecked && defaultOptInInfoWasPrefilled && !didAskToChangeSignupData
    }

    var action: Action? {
        guard saveCheckboxChecked,
              !lookupFailed
        else {
            return .continueWithoutLink
        }

        if linkAccount?.isRegistered ?? false {
            // User already has a Link account, they can't sign up
            if !UserDefaults.standard.customerHasUsedLink {
                STPAnalyticsClient.sharedClient.logLinkSignupFailureAccountExists()
                // Don't bother them again
                UserDefaults.standard.markLinkAsUsed()
            }
            return .continueWithoutLink
        }

        guard let linkAccount = linkAccount else {
            return nil
        }

        switch linkAccount.sessionState {
        case .requiresSignUp:
            guard phoneNumber?.isComplete == true || mode == .signupOptIn else {
                return nil
            }

            if mode != .signupOptIn && requiresNameCollection && !legalNameProvided {
                return nil
            }

            let phone = phoneNumber?.isComplete == true ? phoneNumber : nil

            return .signupAndPay(
                account: linkAccount,
                phoneNumber: phone,
                legalName: requiresNameCollection ? legalName : nil
            )
        case .verified, .requiresVerification:
            // This should never happen: The session should only be verified as part of the signup request,
            // as inline verification is not enabled. Continue without Link.
            return .continueWithoutLink
        }
    }

    var layoutInsets: CGFloat {
        switch mode {
        case .checkbox:
            return 16
        case .checkboxWithDefaultOptIn, .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst, .signupOptIn:
            return 0
        }
    }

    var bordered: Bool {
        switch mode {
        case .checkbox:
            return !useLiquidGlass
        case .checkboxWithDefaultOptIn, .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst, .signupOptIn:
            return false
        }
    }

    var containerBackground: UIColor {
        switch mode {
        case .checkbox:
            if useLiquidGlass {
                return configuration.appearance.colors.componentBackground
            } else {
                return configuration.appearance.colors.background
            }
        case .checkboxWithDefaultOptIn, .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst, .signupOptIn:
            return configuration.appearance.colors.background
        }
    }

    var containerCornerRadius: CGFloat? {
        switch mode {
        case .checkbox:
            return configuration.appearance.cornerRadius
        case .checkboxWithDefaultOptIn, .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst, .signupOptIn:
            // The content is right at the border of the view. Remove the corner radius so that we don't cut off anything.
            return 0
        }
    }

    var combinedEmailNameSectionBorderWidth: CGFloat {
        let borderWidth = configuration.appearance.borderWidth
        switch mode {
        case .checkbox:
            // Make sure we always display at least some border around the section, which is nested in a component
            return max(borderWidth, 1.0)
        case .checkboxWithDefaultOptIn, .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst, .signupOptIn:
            return borderWidth
        }
    }

    var isEmailOptional: Bool {
        switch mode {
        case .checkbox, .checkboxWithDefaultOptIn:
            return false
        case .textFieldsOnlyEmailFirst:
            return true
        case .textFieldsOnlyPhoneFirst:
            return false
        case .signupOptIn:
            // Not applicable
            return true
        }
    }

    var isPhoneNumberOptional: Bool {
        switch mode {
        case .checkbox:
            return false
        case .checkboxWithDefaultOptIn:
            return false
        case .textFieldsOnlyEmailFirst:
            return false
        case .textFieldsOnlyPhoneFirst:
            return true
        case .signupOptIn:
            // Not applicable
            return true
        }
    }

    var showLogoInEmailField: Bool {
        switch mode {
        case .checkbox, .textFieldsOnlyEmailFirst:
            return true
        case .checkboxWithDefaultOptIn:
            // We show it below the signup view
            return false
        case .textFieldsOnlyPhoneFirst:
            // Already shown in the phone number field
            return false
        case .signupOptIn:
            // Not applicable
            return false
        }
    }

    init(
        configuration: PaymentElementConfiguration,
        showCheckbox: Bool,
        accountService: LinkAccountServiceProtocol,
        allowsDefaultOptIn: Bool,
        signupOptInFeatureEnabled: Bool,
        signupOptInInitialValue: Bool,
        linkAccount: PaymentSheetLinkAccount? = nil,
        country: String? = nil,
        analyticsHelper: PaymentSheetAnalyticsHelper? = nil
    ) {
        self.configuration = configuration
        self.accountService = accountService
        self.analyticsHelper = analyticsHelper
        self.linkAccount = linkAccount
        self.emailAddress = linkAccount?.email
        if let email = self.emailAddress,
           !email.isEmpty {
            emailWasPrefilled = true
        }
        if signupOptInFeatureEnabled && emailWasPrefilled {
            self.mode = .signupOptIn
        } else if showCheckbox {
            let allowsDefaultOptIn = allowsDefaultOptIn && country == "US"
            self.mode = allowsDefaultOptIn ? .checkboxWithDefaultOptIn : .checkbox
        } else {
            // If we don't show a checkbox *and* we have a prefilled email, show the phone field first.
            self.mode = (self.emailAddress == nil) ? .textFieldsOnlyEmailFirst : .textFieldsOnlyPhoneFirst
        }
        self.legalName = configuration.defaultBillingDetails.name
        self.country = country

        self.saveCheckboxChecked = {
            switch mode {
            case .checkbox, .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst:
                return false
            case .checkboxWithDefaultOptIn:
                return true
            case .signupOptIn:
                return signupOptInInitialValue
            }
        }()
    }

    func logInlineSignupShown() {
        analyticsHelper?.analyticsClient.logLinkInlineSignupShown(mode: self.mode)
    }
}

enum LinkEmailHelper {
    static func canLookupEmail(_ email: String?) -> Bool {
        let isHideMyEmailDomain = email?.hasSuffix("@privaterelay.appleid.com") == true
        return isHideMyEmailDomain == false
    }
}

private extension LinkInlineSignupViewModel {

    func notifyUpdate() {
        delegate?.signupViewModelDidUpdate(self)
    }

    func onEmailUpdate() {
        linkAccount = nil
        lookupFailed = false

        guard let emailAddress = emailAddress else {
            accountLookupDebouncer.cancel()
            isLookingUpLinkAccount = false
            return
        }

        accountLookupDebouncer.enqueue { [weak self] in
            self?.isLookingUpLinkAccount = true

            self?.accountService.lookupAccount(
                withEmail: emailAddress,
                emailSource: .userAction,
                doNotLogConsumerFunnelEvent: false,
                requestSurface: .default
            ) { result in
                // Check the requested email address against the current one. Handle
                // email address changes while a lookup is in-flight.
                guard emailAddress == self?.emailAddress else {
                    // The email used for this lookup does not match the current address, so we ignore it
                    return
                }
                self?.isLookingUpLinkAccount = false

                switch result {
                case .success(let account):
                    self?.linkAccount = account
                    self?.lookupFailed = false
                case .failure:
                    self?.linkAccount = nil
                    self?.lookupFailed = true
                }
            }
        }
    }

}
