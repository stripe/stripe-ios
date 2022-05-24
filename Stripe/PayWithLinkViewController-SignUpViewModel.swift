//
//  PayWithLinkViewController-SignUpViewModel.swift
//  StripeiOS
//
//  Created by Ramon Torres on 5/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol PayWithLinkSignUpViewModelDelegate: AnyObject {
    func viewModelDidChange(_ viewModel: PayWithLinkViewController.SignUpViewModel)
    func viewModel(
        _ viewModel: PayWithLinkViewController.SignUpViewModel,
        didLookupAccount linkAccount: PaymentSheetLinkAccount?
    )
}

extension PayWithLinkViewController {

    final class SignUpViewModel {
        weak var delegate: PayWithLinkSignUpViewModelDelegate?

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

        private(set) var isLookingUpLinkAccount: Bool = false {
            didSet {
                if isLookingUpLinkAccount != oldValue {
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

        var shouldShowPhoneNumberField: Bool {
            guard let linkAccount = linkAccount else {
                return false
            }

            return !linkAccount.isRegistered
        }

        var shouldShowNameField: Bool {
            guard let linkAccount = linkAccount else {
                return false
            }

            return !linkAccount.isRegistered && requiresNameCollection
        }

        var shouldShowLegalTerms: Bool {
            return shouldShowPhoneNumberField
        }

        var shouldShowSignUpButton: Bool {
            return shouldShowPhoneNumberField
        }

        var shouldEnableSignUpButton: Bool {
            guard let linkAccount = linkAccount,
                  let phoneNumber = phoneNumber
            else {
                return false
            }

            if linkAccount.isRegistered || !phoneNumber.isComplete {
                return false
            }

            if requiresNameCollection && !legalNameProvided {
                return false
            }

            return true
        }

        // MARK: Private properties

        private let accountService: LinkAccountServiceProtocol

        private let accountLookupDebouncer = OperationDebouncer(debounceTime: .milliseconds(500))

        private let configuration: PaymentSheet.Configuration

        private let country: String?

        // MARK: Initializer

        init(
            configuration: PaymentSheet.Configuration,
            accountService: LinkAccountServiceProtocol,
            linkAccount: PaymentSheetLinkAccount?,
            country: String?
        ) {
            self.configuration = configuration
            self.accountService = accountService
            self.linkAccount = linkAccount
            self.emailAddress = linkAccount?.email
            self.legalName = configuration.defaultBillingDetails.name
            self.country = country
        }

        // MARK: Methods

        func signUp(completion: @escaping (Result<PaymentSheetLinkAccount, Error>) -> Void) {
            guard let linkAccount = linkAccount,
                  let phoneNumber = phoneNumber else {
                assertionFailure("`signUp()` called without a link account or phone number")
                return
            }

            linkAccount.signUp(
                with: phoneNumber,
                legalName: requiresNameCollection ? legalName : nil
            ) { [weak self] result in
                switch result {
                case .success():
                    completion(.success(linkAccount))
                case .failure(let error):
                    self?.errorMessage = error.nonGenericDescription
                    completion(.failure(error))
                }
            }
        }

    }

}

private extension PayWithLinkViewController.SignUpViewModel {

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
                guard let self = self else { return }

                self.isLookingUpLinkAccount = false

                switch result {
                case .success(let account):
                    // Check the received email address against the current one. Handle
                    // email address changes while a lookup is in-flight.
                    if account?.email == self.emailAddress {
                        self.linkAccount = account
                        self.delegate?.viewModel(self, didLookupAccount: account)
                    } else {
                        self.linkAccount = nil
                    }
                case .failure(let error):
                    self.errorMessage = error.nonGenericDescription
                }
            }
        }
    }

    func notifyUpdate() {
        delegate?.viewModelDidChange(self)
    }

}
