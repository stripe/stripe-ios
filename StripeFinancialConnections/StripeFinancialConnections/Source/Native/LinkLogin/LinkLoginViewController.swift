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
}

final class LinkLoginViewController: UIViewController {
    private let dataSource: LinkLoginDataSource
    weak var delegate: LinkLoginViewControllerDelegate?

    private lazy var loadingView: SpinnerView = {
        return SpinnerView(theme: dataSource.manifest.theme)
    }()

    private lazy var formView: LinkSignupFormView = {
        let formView = LinkSignupFormView(
            accountholderPhoneNumber: dataSource.manifest.accountholderPhoneNumber,
            theme: dataSource.manifest.theme
        )
        formView.delegate = self
        return formView
    }()

    private var paneLayoutView: PaneLayoutView?
    private var footerButton: StripeUICore.Button?

    init(dataSource: LinkLoginDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor

        showLoadingView(true)
        dataSource
            .synchronize()
            .observe { [weak self] result in
                guard let self else { return }
                self.showLoadingView(false)

                switch result {
                case .success(let linkLoginPane):
                    self.showContent(linkLoginPane: linkLoginPane)
                case .failure(let error):
                    self.delegate?.linkLoginViewController(self, didReceiveTerminalError: error)
                }
            }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setContinueWithLinkButtonDisabledState()
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
            theme: dataSource.manifest.theme,
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

        let emailAddress = dataSource.manifest.accountholderCustomerEmailAddress
        if let emailAddress, !emailAddress.isEmpty {
            formView.prefillEmailAddress(emailAddress)
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
            lookupAccount(with: formView.email)
        } else {
            createAccount()
        }
    }

    private func lookupAccount(with emailAddress: String) {
        formView.emailTextField.showLoadingView(true)

        dataSource
            .lookup(emailAddress: emailAddress)
            .observe { [weak self, weak formView] result in
                formView?.emailTextField.showLoadingView(false)
                guard let self else { return }

                switch result {
                case .success(let response):
                    if response.exists {
                        if response.consumerSession != nil {
                            self.delegate?.linkLoginViewController(self, foundReturningUserWith: response)
                        } else {
                            self.delegate?.linkLoginViewController(
                                self,
                                didReceiveTerminalError: FinancialConnectionsSheetError.unknown(
                                    debugDescription: "No consumer session returned from lookupConsumerSession for emailAddress: \(emailAddress)"
                                )
                            )
                        }
                    } else {
                        formView?.showAndEditPhoneNumberFieldIfNeeded()
                    }
                case .failure(let error):
                    self.delegate?.linkLoginViewController(self, didReceiveTerminalError: error)
                }
            }
    }

    private func createAccount() {
        footerButton?.isLoading = true

        dataSource.signUp(
            emailAddress: formView.email,
            phoneNumber: formView.phoneNumber,
            country: formView.countryCode
        )
        .chained { [weak self] signUpResponse -> Future<FinancialConnectionsSynchronize> in
            guard let self else { return
                Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "data source deallocated"))
            }

            self.delegate?.linkLoginViewController(self, receivedLinkSignUpResponse: signUpResponse)
            return self.dataSource.attachToAccountAndSynchronize(with: signUpResponse)
        }
        .observe { [weak self] result in
            guard let self else { return }
            self.footerButton?.isLoading = false

            switch result {
            case .success(let response):
                self.delegate?.linkLoginViewController(self, signedUpAttachedAndSynchronized: response)
            case .failure(let error):
                self.delegate?.linkLoginViewController(self, didReceiveTerminalError: error)
            }
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
        lookupAccount(with: emailAddress)
    }

    func linkSignupFormViewDidUpdateFields(_ view: LinkSignupFormView) {
        setContinueWithLinkButtonDisabledState()
    }
}
