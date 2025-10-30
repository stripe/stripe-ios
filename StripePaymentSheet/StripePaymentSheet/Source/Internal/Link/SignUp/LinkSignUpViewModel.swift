//
//  LinkSignUpViewModel.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/9/25.
//

import Foundation

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

protocol LinkSignUpViewModelDelegate: AnyObject {
    func viewModelDidChange(_ viewModel: LinkSignUpViewModel)
    func viewModel(
        _ viewModel: LinkSignUpViewModel,
        didLookupAccount linkAccount: PaymentSheetLinkAccount?
    )
    func viewModelDidEncounterAttestationError(_ viewModel: LinkSignUpViewModel)
}

/// For internal SDK use only
@objc(STP_Internal_LinkSignUpViewModel)
final class LinkSignUpViewModel: NSObject {
    weak var delegate: LinkSignUpViewModelDelegate?

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

    private(set) var suggestedEmail: String? {
        didSet {
            if suggestedEmail != oldValue {
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

    var signUpButtonTitle: String {
        shouldShowPhoneNumberField
            ? String.Localized.continue
            : STPLocalizedString(
                "Log in or sign up",
                "Title for a button that indicates a user can log in or sign up."
            )
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
    private let country: String?

    // MARK: Initializer

    init(
        accountService: LinkAccountServiceProtocol,
        linkAccount: PaymentSheetLinkAccount?,
        legalName: String?,
        country: String?
    ) {
        self.accountService = accountService
        self.linkAccount = linkAccount
        self.emailAddress = linkAccount?.email
        self.suggestedEmail = linkAccount?.suggestedEmail
        self.legalName = legalName
        self.country = country
        super.init()
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
            countryCode: nil,
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

private extension LinkSignUpViewModel {

    func onEmailUpdate() {
        linkAccount = nil
        errorMessage = nil
        suggestedEmail = nil

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
                    self.suggestedEmail = account?.suggestedEmail
                    self.delegate?.viewModel(self, didLookupAccount: account)
                case .failure(let error):
                    self.linkAccount = nil
                    if StripeAttest.isLinkAssertionError(error: error) {
                        self.delegate?.viewModelDidEncounterAttestationError(self)
                    } else {
                        self.errorMessage = error.nonGenericDescription
                    }
                }
            }
        }
    }

    func notifyUpdate() {
        delegate?.viewModelDidChange(self)
    }

}
