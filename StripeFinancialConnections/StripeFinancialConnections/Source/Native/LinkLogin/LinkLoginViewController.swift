//
//  LinkLoginViewController.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-07-25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol LinkLoginViewControllerDelegate: AnyObject {
    func linkLoginViewController(
        _ viewController: LinkLoginViewController,
        foundReturningUserWith lookupConsumerSessionResponse: LookupConsumerSessionResponse
    )

    func linkLoginViewController(
        _ viewController: LinkLoginViewController,
        receivedLinkSignUpResponse linkSignUpResponse: LinkSignUpResponse
    )

    func linkLoginViewController(
        _ viewController: LinkLoginViewController,
        signedUpAttachedAndSynchronized synchronizePayload: FinancialConnectionsSynchronize
    )

    func linkLoginViewController(
        _ viewController: LinkLoginViewController,
        didReceiveTerminalError error: Error
    )

    func linkLoginViewControllerDidFailAttestationVerdict(
        _ viewController: LinkLoginViewController,
        prefillDetails: WebPrefillDetails
    )
}

final class LinkLoginViewController: UIViewController {
    private let dataSource: LinkLoginDataSource
    weak var delegate: LinkLoginViewControllerDelegate?

    private lazy var loadingView: SpinnerView = {
        return SpinnerView(appearance: dataSource.manifest.appearance)
    }()

    private lazy var formView: LinkSignupFormView = {
        let formView = LinkSignupFormView(
            accountholderPhoneNumber: dataSource.manifest.accountholderPhoneNumber,
            appearance: dataSource.manifest.appearance
        )
        formView.delegate = self
        return formView
    }()

    private var paneLayoutView: PaneLayoutView?
    private var footerButton: StripeUICore.Button?
    private var prefillEmailAddress: String? {
        let email = dataSource.manifest.accountholderCustomerEmailAddress ?? dataSource.elementsSessionContext?.prefillDetails?.email
        return email?.isEmpty == false ? email : nil
    }

    init(dataSource: LinkLoginDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background

        showLoadingView(true)

        Task {
            await synchronize()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setContinueWithLinkButtonDisabledState()
    }

    private func synchronize() async {
        do {
            let linkLoginPane = try await dataSource.synchronize()
            await MainActor.run {
                showLoadingView(false)
                showContent(linkLoginPane: linkLoginPane)
            }
        } catch {
            await MainActor.run {
                showLoadingView(false)
            }
            delegate?.linkLoginViewController(self, didReceiveTerminalError: error)
        }
    }

    private func showContent(linkLoginPane: FinancialConnectionsLinkLoginPane) {
        let contentView = PaneLayoutView.createContentView(
            iconView: nil,
            title: linkLoginPane.title,
            subtitle: linkLoginPane.body,
            contentView: formView
        )
        let footerView = PaneLayoutView.createFooterView(
            primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                title: linkLoginPane.cta,
                accessibilityIdentifier: "link_login.primary_button",
                action: didSelectContinueWithLink
            ),
            topText: linkLoginPane.aboveCta,
            appearance: dataSource.manifest.appearance,
            didSelectURL: didSelectURLInTextFromBackend
        )
        self.footerButton = footerView.primaryButton

        self.paneLayoutView = PaneLayoutView(
            contentView: contentView,
            footerView: footerView.footerView,
            keepFooterAboveKeyboard: true
        )

        paneLayoutView?.addTo(view: view)

        #if !canImport(CompositorServices)
        // if user drags, dismiss keyboard so the CTA buttons can be shown
        paneLayoutView?.scrollView.keyboardDismissMode = .onDrag
        #endif

        if let prefillEmailAddress {
            // Immediately set the button state to loading here to bypass the debouncing by the textfield.
            footerButton?.isLoading = true
            formView.prefillEmailAddress(prefillEmailAddress)

            let phoneNumber = dataSource.manifest.accountholderPhoneNumber ?? dataSource.elementsSessionContext?.prefillDetails?.formattedPhoneNumber
            formView.prefillPhoneNumber(phoneNumber)
        } else {
            // Slightly delay opening the keyboard to avoid a janky animation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.formView.beginEditingEmailAddressField()
            }
        }

        setContinueWithLinkButtonDisabledState()
    }

    private func showLoadingView(_ show: Bool) {
        if show && loadingView.superview == nil {
            view.addAndPinSubviewToSafeArea(loadingView)
        }

        loadingView.isHidden = !show
        view.bringSubviewToFront(loadingView)
    }

    private func didSelectContinueWithLink() {
        if formView.phoneNumber.isEmpty {
            Task {
                await lookupAccount(with: formView.email)
            }
        } else {
            Task {
                await createAccount()
            }
        }
    }

    private func lookupAccount(with emailAddress: String) async {
        formView.emailTextField.showLoadingView(true)
        footerButton?.isLoading = true

        let manuallyEnteredEmail = emailAddress != prefillEmailAddress
        do {
            let response = try await dataSource.lookup(
                emailAddress: emailAddress,
                manuallyEntered: manuallyEnteredEmail
            )

            await MainActor.run {
                formView.emailTextField.showLoadingView(false)
                footerButton?.isLoading = false
            }

            dataSource.completeAssertionIfNeeded(possibleError: nil, api: .consumerSessionLookup)

            if response.exists {
                if response.consumerSession != nil {
                    delegate?.linkLoginViewController(self, foundReturningUserWith: response)
                } else {
                    delegate?.linkLoginViewController(
                        self,
                        didReceiveTerminalError: FinancialConnectionsSheetError.unknown(
                            debugDescription: "No consumer session returned from lookupConsumerSession for emailAddress: \(emailAddress)"
                        )
                    )
                }
            } else {
                await MainActor.run {
                    formView.showAndEditPhoneNumberFieldIfNeeded()
                }
            }
        } catch {
            await MainActor.run {
                formView.emailTextField.showLoadingView(false)
                footerButton?.isLoading = false
            }

            let attestationError = dataSource.completeAssertionIfNeeded(
                possibleError: error,
                api: .consumerSessionLookup
            )

            if attestationError != nil {
                let prefillDetails = WebPrefillDetails(email: emailAddress)
                delegate?.linkLoginViewControllerDidFailAttestationVerdict(self, prefillDetails: prefillDetails)
            } else {
                delegate?.linkLoginViewController(self, didReceiveTerminalError: error)
            }
        }
    }

    private func createAccount() async {
        footerButton?.isLoading = true

        do {
            let signUpResponse = try await dataSource.signUp(
                emailAddress: formView.email,
                phoneNumber: formView.phoneNumber,
                country: formView.countryCode
            )
            delegate?.linkLoginViewController(self, receivedLinkSignUpResponse: signUpResponse)

            let syncResponse = try await dataSource.attachToAccountAndSynchronize(with: signUpResponse)

            await MainActor.run {
                footerButton?.isLoading = false
            }

            dataSource.completeAssertionIfNeeded(possibleError: nil, api: .linkSignUp)
            delegate?.linkLoginViewController(self, signedUpAttachedAndSynchronized: syncResponse)
        } catch {
            await MainActor.run {
                footerButton?.isLoading = false
            }

            let attestationError = dataSource.completeAssertionIfNeeded(
                possibleError: error,
                api: .linkSignUp
            )

            if attestationError != nil {
                let prefillDetails = WebPrefillDetails(
                    email: formView.email,
                    phone: formView.phoneNumber,
                    countryCode: formView.countryCode
                )
                delegate?.linkLoginViewControllerDidFailAttestationVerdict(self, prefillDetails: prefillDetails)
                return
            }

            delegate?.linkLoginViewController(self, didReceiveTerminalError: error)
        }
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .linkLogin,
            analyticsClient: dataSource.analyticsClient,
            handleURL: { _, _ in /* Stripe scheme URLs are not expected. */ }
        )
    }

    private func setContinueWithLinkButtonDisabledState() {
        let isEmailValid = formView.emailTextField.isEmailValid

        if formView.phoneTextField.isHidden {
            footerButton?.isEnabled = isEmailValid
        } else {
            let isPhoneNumberValid = formView.phoneTextField.isPhoneNumberValid
            footerButton?.isEnabled = isEmailValid && isPhoneNumberValid
        }
    }
}

extension LinkLoginViewController: LinkSignupFormViewDelegate {
    func linkSignupFormView(_ view: LinkSignupFormView, didEnterValidEmailAddress emailAddress: String) {
        Task {
            await lookupAccount(with: emailAddress)
        }
    }

    func linkSignupFormViewDidUpdateFields(_ view: LinkSignupFormView) {
        setContinueWithLinkButtonDisabledState()
    }
}
