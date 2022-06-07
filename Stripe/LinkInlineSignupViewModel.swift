//
//  LinkInlineSignupViewModel.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/19/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
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

    weak var delegate: LinkInlineSignupViewModelDelegate?

    private let accountService: LinkAccountServiceProtocol

    private let accountLookupDebouncer = OperationDebouncer(debounceTime: .milliseconds(500))

    private let country: String?

    let configuration: PaymentSheet.Configuration

    var saveCheckboxChecked: Bool = false {
        didSet {
            if saveCheckboxChecked != oldValue {
                notifyUpdate()

                if saveCheckboxChecked {
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

    var requiresNameCollection: Bool {
        return country != "US"
    }

    var legalNameProvided: Bool {
        guard let legalName = legalName else {
            return false
        }

        return !legalName.isBlank
    }

    var shouldShowEmailField: Bool {
        return saveCheckboxChecked
    }

    var shouldShowNameField: Bool {
        guard saveCheckboxChecked,
              let linkAccount = linkAccount else {
            return false
        }

        return !linkAccount.isRegistered && requiresNameCollection
    }

    var shouldShowPhoneField: Bool {
        guard saveCheckboxChecked,
              let linkAccount = linkAccount
        else {
            return false
        }

        return !linkAccount.isRegistered
    }

    var shouldShowLegalTerms: Bool {
        return shouldShowPhoneField
    }

    var action: Action? {
        guard saveCheckboxChecked,
              !lookupFailed
        else {
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

    init(
        configuration: PaymentSheet.Configuration,
        accountService: LinkAccountServiceProtocol,
        linkAccount: PaymentSheetLinkAccount? = nil,
        country: String? = nil
    ) {
        self.configuration = configuration
        self.accountService = accountService
        self.linkAccount = linkAccount
        self.emailAddress = linkAccount?.email
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
                case .failure(_):
                    self?.linkAccount = nil
                    self?.lookupFailed = true
                }
            }
        }
    }

}
