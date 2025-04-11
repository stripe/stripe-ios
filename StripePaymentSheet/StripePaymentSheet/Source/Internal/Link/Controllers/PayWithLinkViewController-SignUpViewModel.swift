//
//  PayWithLinkViewController-SignUpViewModel.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 5/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

protocol PayWithLinkSignUpViewModelDelegate: AnyObject {
    func viewModelDidChange(_ viewModel: PayWithLinkViewController.SignUpViewModel)
    func viewModel(
        _ viewModel: PayWithLinkViewController.SignUpViewModel,
        didLookupAccount linkAccount: PaymentSheetLinkAccount?
    )
    func viewModelDidEncounterAttestationError(
        _ viewModel: PayWithLinkViewController.SignUpViewModel
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

        private let accountLookupDebouncer = OperationDebouncer(debounceTime: LinkUI.accountLookupDebounceTime)

        private let configuration: PaymentElementConfiguration

        private let country: String?

        // MARK: Initializer

        init(
            configuration: PaymentElementConfiguration,
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
                stpAssertionFailure("`signUp()` called without a link account or phone number")
                return
            }

            linkAccount.signUp(
                with: phoneNumber,
                legalName: requiresNameCollection ? legalName : nil,
                consentAction: .clicked_button_mobile_v1
            ) { [weak self] result in
                switch result {
                case .success:
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
            isLookingUpLinkAccount = false
            return
        }

        accountLookupDebouncer.enqueue { [weak self] in
            self?.isLookingUpLinkAccount = true

            self?.accountService.lookupAccount(
                withEmail: emailAddress,
                emailSource: .userAction,
                doNotLogConsumerFunnelEvent: false
            ) { result in
                guard let self = self else { return }

                // Check the requested email address against the current one. Handle
                // email address changes while a lookup is in-flight.
                guard emailAddress == self.emailAddress else {
                    // The email used for this lookup does not match the current address, so we ignore it
                    return
                }

                self.isLookingUpLinkAccount = false

                switch result {
                case .success(let account):
                    self.linkAccount = account
                    self.delegate?.viewModel(self, didLookupAccount: account)
                case .failure(let error):
                    self.linkAccount = nil
                    self.errorMessage = error.nonGenericDescription
                    if StripeAttest.isLinkAssertionError(error: error) {
                        self.delegate?.viewModelDidEncounterAttestationError(self)
                    }
                }
            }
        }
    }

    func notifyUpdate() {
        delegate?.viewModelDidChange(self)
    }

}
