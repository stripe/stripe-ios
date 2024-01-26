//
//  LinkInlineSignupViewModel.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/19/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

protocol LinkInlineSignupViewModelDelegate: AnyObject {
    func signupViewModelDidUpdate(_ viewModel: LinkInlineSignupViewModel)
}

final class LinkInlineSignupViewModel {
    enum Action: Equatable {
        case pay(account: PaymentSheetLinkAccount)
        case signupAndPay(account: PaymentSheetLinkAccount, phoneNumber: PhoneNumber, legalName: String?)
        case continueWithoutLink
    }

    enum Mode {
        case checkbox // shows the Link inline signup with the checkbox and nested form fields
        case textFieldsOnlyEmailFirst // shows the Link inline signup without the checkbox, email field first
        case textFieldsOnlyPhoneFirst // shows the Link inline signup without the checkbox, phone number field first
    }

    weak var delegate: LinkInlineSignupViewModelDelegate?

    private let accountService: LinkAccountServiceProtocol

    private let accountLookupDebouncer = OperationDebouncer(debounceTime: LinkUI.accountLookupDebounceTime)

    private let country: String?

    let configuration: PaymentSheet.Configuration

    let mode: Mode

    var saveCheckboxChecked: Bool = false {
        didSet {
            if saveCheckboxChecked != oldValue {
                notifyUpdate()

                if saveCheckboxChecked, mode == .checkbox {
                    STPAnalyticsClient.sharedClient.logLinkSignupCheckboxChecked()
                }
            }
        }
    }

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

    private(set) var linkAccount: PaymentSheetLinkAccount? {
        didSet {
            if linkAccount !== oldValue {
                notifyUpdate()

                if let linkAccount = linkAccount,
                   linkAccount.isRegistered {
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
        case .textFieldsOnlyEmailFirst:
            return true
        case .textFieldsOnlyPhoneFirst:
            // Only show email if the phone number field has contents
            return (phoneNumber?.isComplete ?? false)
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
        case .textFieldsOnlyPhoneFirst:
            return requiresNameCollection && phoneNumber?.isComplete ?? false
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
        case .textFieldsOnlyPhoneFirst:
            return true
        }
    }

    var shouldShowLegalTerms: Bool {
        switch mode {
        case .checkbox:
            return shouldShowPhoneField
        case .textFieldsOnlyPhoneFirst, .textFieldsOnlyEmailFirst:
            return true
        }
    }

    var action: Action? {
        guard saveCheckboxChecked,
              !lookupFailed
        else {
            return .continueWithoutLink
        }

        if linkAccount?.isRegistered ?? false {
            // User already has a Link account, they can't sign up
            STPAnalyticsClient.sharedClient.logLinkSignupFailureAccountExists()
            // Don't bother them again
            UserDefaults.standard.markLinkAsUsed()
            return .continueWithoutLink
        }

        guard let linkAccount = linkAccount else {
            return nil
        }

        switch linkAccount.sessionState {
        case .requiresSignUp:
            guard let phoneNumber = phoneNumber,
                  phoneNumber.isComplete else {
                return nil
            }

            if requiresNameCollection && !legalNameProvided {
                return nil
            }

            return .signupAndPay(
                account: linkAccount,
                phoneNumber: phoneNumber,
                legalName: requiresNameCollection ? legalName : nil
            )
        case .verified, .requiresVerification:
            return .pay(account: linkAccount)
        }
    }

    var layoutInsets: CGFloat {
        switch mode {
        case .checkbox:
            return 16
        case .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst:
            return 0
        }
    }

    var showCheckbox: Bool {
        switch mode {
        case .checkbox:
            return true
        case .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst:
            return false
        }
    }

    var bordered: Bool {
        switch mode {
        case .checkbox:
            return true
        case .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst:
            return false
        }
    }

    var isEmailOptional: Bool {
        switch mode {
        case .checkbox:
            return false
        case .textFieldsOnlyEmailFirst:
            return true
        case .textFieldsOnlyPhoneFirst:
            return false
        }
    }

    var isPhoneNumberOptional: Bool {
        switch mode {
        case .checkbox:
            return false
        case .textFieldsOnlyEmailFirst:
            return false
        case .textFieldsOnlyPhoneFirst:
            return true
        }
    }

    init(
        configuration: PaymentSheet.Configuration,
        showCheckbox: Bool,
        accountService: LinkAccountServiceProtocol,
        linkAccount: PaymentSheetLinkAccount? = nil,
        country: String? = nil
    ) {
        self.configuration = configuration
        self.accountService = accountService
        self.linkAccount = linkAccount
        self.emailAddress = linkAccount?.email
        if showCheckbox {
            self.mode = .checkbox
        } else {
            // If we don't show a checkbox *and* we have a prefilled email, show the phone field first.
            self.mode = (self.emailAddress == nil) ? .textFieldsOnlyEmailFirst : .textFieldsOnlyPhoneFirst
        }
        self.legalName = configuration.defaultBillingDetails.name
        self.country = country
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

            self?.accountService.lookupAccount(withEmail: emailAddress) { result in
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
