//
//  NetworkingLinkSignupViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/17/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol NetworkingLinkSignupViewControllerDelegate: AnyObject {
    func networkingLinkSignupViewController(
        _ viewController: NetworkingLinkSignupViewController,
        foundReturningConsumerWithSession consumerSession: ConsumerSessionData
    )
    func networkingLinkSignupViewControllerDidFinish(
        _ viewController: NetworkingLinkSignupViewController,
        // nil == we did not perform saveToLink
        saveToLinkWithStripeSucceeded: Bool?,
        withError error: Error?
    )
    func networkingLinkSignupViewController(
        _ viewController: NetworkingLinkSignupViewController,
        didReceiveTerminalError error: Error
    )
}

final class NetworkingLinkSignupViewController: UIViewController {

    private let dataSource: NetworkingLinkSignupDataSource
    weak var delegate: NetworkingLinkSignupViewControllerDelegate?

    private lazy var loadingView: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.color = .textDisabled
        activityIndicator.backgroundColor = .customBackgroundColor
        return activityIndicator
    }()
    private lazy var formView: NetworkingLinkSignupBodyFormView = {
        let formView = NetworkingLinkSignupBodyFormView(
            accountholderPhoneNumber: dataSource.manifest.accountholderPhoneNumber
        )
        formView.delegate = self
        return formView
    }()
    private var footerView: NetworkingLinkSignupFooterView?
    private var viewDidAppear: Bool = false
    private var willNavigateToReturningConsumer = false

    init(dataSource: NetworkingLinkSignupDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        view.backgroundColor = .customBackgroundColor

        showLoadingView(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // delay executing logic until `viewDidAppear` because
        // of janky keyboard animations
        if !viewDidAppear {
            viewDidAppear = true
            dataSource.synchronize()
                .observe { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let networkingLinkSignup):
                        self.showContent(networkingLinkSignup: networkingLinkSignup)
                    case .failure(let error):
                        self.dataSource
                            .analyticsClient
                            .logUnexpectedError(
                                error,
                                errorName: "NetworkingLinkSignupSynchronizeError",
                                pane: .networkingLinkSignupPane
                            )
                        self.delegate?.networkingLinkSignupViewControllerDidFinish(
                            self,
                            saveToLinkWithStripeSucceeded: nil,
                            withError: error
                        )
                    }
                    self.showLoadingView(false) // first set to `true` from `viewDidLoad`
                }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if willNavigateToReturningConsumer {
            willNavigateToReturningConsumer = false
            // in case a user decides to go back from verification pane,
            // we clear the email so they can re-enter
            formView.emailElement.emailAddressElement.setText("")
        }
    }

    private func showContent(networkingLinkSignup: FinancialConnectionsNetworkingLinkSignup) {
        let footerView = NetworkingLinkSignupFooterView(
            aboveCtaText: networkingLinkSignup.aboveCta,
            saveToLinkButtonText: networkingLinkSignup.cta,
            notNowButtonText: networkingLinkSignup.skipCta,
            didSelectSaveToLink: { [weak self] in
                self?.didSelectSaveToLink()
            },
            didSelectNotNow: { [weak self] in
                guard let self = self else {
                    return
                }
                self.dataSource.analyticsClient
                    .log(
                        eventName: "click.not_now",
                        pane: .networkingLinkSignupPane
                    )
                self.delegate?.networkingLinkSignupViewControllerDidFinish(
                    self,
                    saveToLinkWithStripeSucceeded: nil,
                    withError: nil
                )
            },
            didSelectURL: { [weak self] url in
                self?.didSelectURLInTextFromBackend(url)
            }
        )
        self.footerView = footerView
        let pane = PaneWithHeaderLayoutView(
            title: networkingLinkSignup.title,
            contentView: NetworkingLinkSignupBodyView(
                bulletPoints: networkingLinkSignup.body.bullets,
                formView: formView,
                didSelectURL: { [weak self] url in
                    self?.didSelectURLInTextFromBackend(url)
                }
            ),
            footerView: footerView
        )
        pane.addTo(view: view)

        #if !canImport(CompositorServices)
        // if user drags, dismiss keyboard so the CTA buttons can be shown
        pane.scrollView.keyboardDismissMode = .onDrag
        #endif

        let emailAddress = dataSource.manifest.accountholderCustomerEmailAddress
        if let emailAddress = emailAddress, !emailAddress.isEmpty {
            formView.prefillEmailAddress(dataSource.manifest.accountholderCustomerEmailAddress)
        }

        assert(self.footerView != nil, "footer view should be initialized as part of displaying content")
    }

    private func showLoadingView(_ show: Bool) {
        if show && loadingView.superview == nil {
            // first-time we are showing this, so add the view to hierarchy
            view.addAndPinSubview(loadingView)
        }

        loadingView.isHidden = !show
        if show {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
        view.bringSubviewToFront(loadingView)  // defensive programming to avoid loadingView being hiddden
    }

    private func didSelectSaveToLink() {
        footerView?.setIsLoading(true)
        dataSource
            .analyticsClient
            .log(
                eventName: "click.save_to_link",
                pane: .networkingLinkSignupPane
            )

        dataSource.saveToLink(
            emailAddress: formView.emailElement.emailAddressString ?? "",
            phoneNumber: formView.phoneNumberElement.phoneNumber?.string(as: .e164) ?? "",
            countryCode: formView.phoneNumberElement.phoneNumber?.countryCode ?? "US"
        )
        .observe { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.delegate?.networkingLinkSignupViewControllerDidFinish(
                    self,
                    saveToLinkWithStripeSucceeded: true,
                    withError: nil
                )
            case .failure(let error):
                // on error, we still go to success pane, but show a small error
                // notice above the done button of the success pane
                self.delegate?.networkingLinkSignupViewControllerDidFinish(
                    self,
                    saveToLinkWithStripeSucceeded: false,
                    withError: error
                )
                self.dataSource.analyticsClient.logUnexpectedError(
                    error,
                    errorName: "SaveToLinkError",
                    pane: .networkingLinkSignupPane
                )
            }
            self.footerView?.setIsLoading(false)
        }
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .networkingLinkSignupPane,
            analyticsClient: dataSource.analyticsClient,
            handleStripeScheme: { _ in
                // no custom stripe scheme is handled
            }
        )
    }

    private func adjustSaveToLinkButtonDisabledState() {
        let isEmailValid = formView.emailElement.validationState.isValid
        let isPhoneNumberValid = formView.phoneNumberElement.validationState.isValid
        footerView?.enableSaveToLinkButton(isEmailValid && isPhoneNumberValid)
    }

    private func foundReturningConsumer(withSession consumerSession: ConsumerSessionData) {
        willNavigateToReturningConsumer = true
        delegate?.networkingLinkSignupViewController(
            self,
            foundReturningConsumerWithSession: consumerSession
        )
    }
}

extension NetworkingLinkSignupViewController: NetworkingLinkSignupBodyFormViewDelegate {

    func networkingLinkSignupBodyFormView(
        _ bodyFormView: NetworkingLinkSignupBodyFormView,
        didEnterValidEmailAddress emailAddress: String
    ) {
        bodyFormView.emailElement.startAnimating()
        dataSource
            .lookup(emailAddress: emailAddress)
            .observe { [weak self, weak bodyFormView] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    if response.exists {
                        self.dataSource.analyticsClient.log(
                            eventName: "networking.returning_consumer",
                            pane: .networkingLinkSignupPane
                        )
                        if let consumerSession = response.consumerSession {
                            // TODO(kgaidis): check whether its fair to assume that we will always have a consumer sesion here
                            self.foundReturningConsumer(withSession: consumerSession)
                        } else {
                            self.delegate?.networkingLinkSignupViewControllerDidFinish(
                                self,
                                saveToLinkWithStripeSucceeded: nil,
                                withError: FinancialConnectionsSheetError.unknown(
                                    debugDescription: "No consumer session returned from lookupConsumerSession for emailAddress: \(emailAddress)"
                                )
                            )
                        }
                    } else {
                        self.dataSource.analyticsClient.log(
                            eventName: "networking.new_consumer",
                            pane: .networkingLinkSignupPane
                        )

                        let didShowPhoneNumberFieldForTheFirstTime = self.formView.showPhoneNumberFieldIfNeeded()
                        // in case user needs to slowly re-type the e-mail,
                        // we want to only jump to the phone number the
                        // first time they enter the e-mail
                        if didShowPhoneNumberFieldForTheFirstTime {
                            let didPrefillPhoneNumber = (self.formView.phoneNumberElement.phoneNumber?.number ?? "").count > 1
                            // if the phone number is pre-filled, we don't focus on the phone number field
                            if !didPrefillPhoneNumber {
                                let didPrefillEmailAddress = {
                                    if
                                        let accountholderCustomerEmailAddress = self.dataSource.manifest.accountholderCustomerEmailAddress,
                                        !accountholderCustomerEmailAddress.isEmpty
                                    {
                                        return true
                                    } else {
                                        return false
                                    }
                                }()
                                // we don't want to auto-focus the phone number field if we pre-filled the email
                                if !didPrefillEmailAddress {
                                    // this disables the "Phone" label animating (we don't want that animation here)
                                    UIView.performWithoutAnimation {
                                        self.formView.beginEditingPhoneNumberField()
                                    }
                                }
                            } else {
                                // user is done with e-mail AND phone number, so dismiss the keyboard
                                // so they can see the "Save to Link" button
                                self.formView.endEditingEmailAddressField()
                            }
                        }
                        self.footerView?.showSaveToLinkButtonIfNeeded()
                    }
                case .failure(let error):
                    self.dataSource.analyticsClient.logUnexpectedError(
                        error,
                        errorName: "LookupConsumerSessionError",
                        pane: .networkingLinkSignupPane
                    )
                    self.delegate?.networkingLinkSignupViewController(
                        self,
                        didReceiveTerminalError: error
                    )
                }
                bodyFormView?.emailElement.stopAnimating()
            }
    }

    func networkingLinkSignupBodyFormViewDidUpdateFields(_ view: NetworkingLinkSignupBodyFormView) {
        adjustSaveToLinkButtonDisabledState()
    }
}
