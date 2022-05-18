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
    enum Action {
        case pay(account: PaymentSheetLinkAccount)
        case signupAndPay(account: PaymentSheetLinkAccount, phoneNumber: PhoneNumber, legalName: String?)
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
    
    private(set) var errorMessage: String? {
        didSet {
            if errorMessage != oldValue {
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

    var signupDetails: Action? {
        guard saveCheckboxChecked,
              let linkAccount = linkAccount else {
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

            return .signupAndPay(account: linkAccount, phoneNumber: phoneNumber, legalName: legalName)
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
        self.country = country
    }

}

private extension LinkInlineSignupViewModel {

    func notifyUpdate() {
        delegate?.signupViewModelDidUpdate(self)
    }

    func onEmailUpdate() {
        linkAccount = nil
        errorMessage = nil
        
        guard let emailAddress = emailAddress else {
            accountLookupDebouncer.cancel()
            return
        }

        accountLookupDebouncer.enqueue { [weak self] in
            self?.isLookingUpLinkAccount = true

            self?.accountService.lookupAccount(withEmail: emailAddress) { result in
                self?.isLookingUpLinkAccount = false

                switch result {
                case .success(let account):
                    // Check the received email address against the current one. Handle
                    // email address changes while a lookup is in-flight.
                    if account?.email == self?.emailAddress {
                        self?.linkAccount = account
                    } else {
                        self?.linkAccount = nil
                    }
                case .failure(let error):
                    self?.errorMessage = error.nonGenericDescription
                    break
                }
            }
        }
    }

}
