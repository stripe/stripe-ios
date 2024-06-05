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
        customSuccessPaneMessage: String?,
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

    private lazy var loadingView: SpinnerView = {
        return SpinnerView()
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
                            customSuccessPaneMessage: nil,
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
            formView.emailTextField.text = ""
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
                    customSuccessPaneMessage: nil,
                    withError: nil
                )
            },
            didSelectURL: { [weak self] url in
                self?.didSelectURLInTextFromBackend(
                    url,
                    legalDetailsNotice: networkingLinkSignup.legalDetailsNotice
                )
            }
        )
        self.footerView = footerView
        let paneLayoutView = PaneLayoutView(
            contentView: PaneLayoutView.createContentView(
                iconView: nil,
                title: networkingLinkSignup.title,
                subtitle: nil,
                contentView: NetworkingLinkSignupBodyView(
                    bulletPoints: networkingLinkSignup.body.bullets,
                    formView: formView,
                    didSelectURL: { [weak self] url in
                        self?.didSelectURLInTextFromBackend(
                            url,
                            legalDetailsNotice: networkingLinkSignup.legalDetailsNotice
                        )
                    }
                )
            ),
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)

        #if !canImport(CompositorServices)
        // if user drags, dismiss keyboard so the CTA buttons can be shown
        paneLayoutView.scrollView.keyboardDismissMode = .onDrag
        #endif

        let emailAddress = dataSource.manifest.accountholderCustomerEmailAddress
        if let emailAddress, !emailAddress.isEmpty {
            formView.prefillEmailAddress(emailAddress)
        } else {
            formView.beginEditingEmailAddressField()
        }

        assert(self.footerView != nil, "footer view should be initialized as part of displaying content")

        // disable CTA if needed
        adjustSaveToLinkButtonDisabledState()
    }

    private func showLoadingView(_ show: Bool) {
        if show && loadingView.superview == nil {
            // first-time we are showing this, so add the view to hierarchy
            view.addAndPinSubviewToSafeArea(loadingView)
        }

        loadingView.isHidden = !show
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
            emailAddress: formView.emailTextField.text,
            phoneNumber: formView.phoneTextField.phoneNumber?.string(as: .e164) ?? "",
            countryCode: formView.phoneTextField.phoneNumber?.countryCode ?? "US"
        )
        .observe { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let customSuccessPaneMessage):
                self.delegate?.networkingLinkSignupViewControllerDidFinish(
                    self,
                    saveToLinkWithStripeSucceeded: true,
                    customSuccessPaneMessage: customSuccessPaneMessage,
                    withError: nil
                )
            case .failure(let error):
                // on error, we still go to success pane, but show a small error
                // notice above the done button of the success pane
                self.delegate?.networkingLinkSignupViewControllerDidFinish(
                    self,
                    saveToLinkWithStripeSucceeded: false,
                    customSuccessPaneMessage: nil,
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

    private func didSelectURLInTextFromBackend(
        _ url: URL,
        legalDetailsNotice: FinancialConnectionsLegalDetailsNotice?
    ) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .networkingLinkSignupPane,
            analyticsClient: dataSource.analyticsClient,
            handleStripeScheme: { urlHost in
                if urlHost == "legal-details-notice", let legalDetailsNotice {
                    let legalDetailsNoticeViewController = LegalDetailsNoticeViewController(
                        legalDetailsNotice: legalDetailsNotice,
                        didSelectUrl: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(
                                url,
                                legalDetailsNotice: legalDetailsNotice
                            )
                        }
                    )
                    legalDetailsNoticeViewController.present(on: self)
                }
            }
        )
    }

    private func adjustSaveToLinkButtonDisabledState() {
        let isEmailValid = formView.emailTextField.isEmailValid
        let isPhoneNumberValid = formView.phoneTextField.isPhoneNumberValid
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
        bodyFormView.emailTextField.showLoadingView(true)
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
                                customSuccessPaneMessage: nil,
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
                            let didPrefillPhoneNumber = (self.formView.phoneTextField.phoneNumber?.number ?? "").count > 1
                            if !didPrefillPhoneNumber {
                                // this disables the "Phone" label animating (we don't want that animation here)
                                UIView.performWithoutAnimation {
                                    // auto-focus the non-prefilled phone field
                                    self.formView.beginEditingPhoneNumberField()
                                }
                            } else {
                                // user is done with e-mail AND phone number, so dismiss the keyboard
                                // so they can see the "Save to Link" button
                                self.formView.endEditingEmailAddressField()
                            }
                        }
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
                bodyFormView?.emailTextField.showLoadingView(false)
            }
    }

    func networkingLinkSignupBodyFormViewDidUpdateFields(_ view: NetworkingLinkSignupBodyFormView) {
        adjustSaveToLinkButtonDisabledState()
    }
}
