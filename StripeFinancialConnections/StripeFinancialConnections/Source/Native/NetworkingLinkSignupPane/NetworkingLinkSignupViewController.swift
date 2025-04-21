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
    func networkingLinkSignupViewControllerDidFailAttestationVerdict(
        _ viewController: NetworkingLinkSignupViewController,
        prefillDetails: WebPrefillDetails
    )
}

final class NetworkingLinkSignupViewController: UIViewController {

    private let dataSource: NetworkingLinkSignupDataSource
    weak var delegate: NetworkingLinkSignupViewControllerDelegate?

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
    private var footerView: NetworkingLinkSignupFooterView?
    private var viewDidAppear: Bool = false
    private var willNavigateToReturningConsumer = false
    private var prefillEmailAddress: String? {
        let email = dataSource.manifest.accountholderCustomerEmailAddress ?? dataSource.elementsSessionContext?.prefillDetails?.email
        return email?.isEmpty == false ? email : nil
    }

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
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background

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
            appearance: dataSource.manifest.appearance,
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

        if let prefillEmailAddress {
            formView.prefillEmailAddress(prefillEmailAddress)

            let phoneNumber = dataSource.manifest.accountholderPhoneNumber ?? dataSource.elementsSessionContext?.prefillDetails?.formattedPhoneNumber
            formView.prefillPhoneNumber(phoneNumber)
        } else {
            // Slightly delay opening the keyboard to avoid a janky animation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.formView.beginEditingEmailAddressField()
            }
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
            emailAddress: formView.email,
            phoneNumber: formView.phoneNumber,
            countryCode: formView.countryCode
        )
        .observe { [weak self] result in
            guard let self = self else { return }
            let attestationError = self.dataSource.completeAssertionIfNeeded(
                possibleError: result.error,
                api: .linkSignUp
            )
            if attestationError != nil {
                let prefillDetails = WebPrefillDetails(
                    email: self.formView.email,
                    phone: self.formView.phoneNumber,
                    countryCode: self.formView.countryCode
                )
                self.delegate?.networkingLinkSignupViewControllerDidFailAttestationVerdict(
                    self,
                    prefillDetails: prefillDetails
                )
                return
            }

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
            handleURL: { urlHost, _ in
                if urlHost == "legal-details-notice", let legalDetailsNotice {
                    let legalDetailsNoticeViewController = LegalDetailsNoticeViewController(
                        legalDetailsNotice: legalDetailsNotice,
                        appearance: dataSource.manifest.appearance,
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

extension NetworkingLinkSignupViewController: LinkSignupFormViewDelegate {

    func linkSignupFormView(
        _ bodyFormView: LinkSignupFormView,
        didEnterValidEmailAddress emailAddress: String
    ) {
        bodyFormView.emailTextField.showLoadingView(true)
        let manuallyEnteredEmail = emailAddress != prefillEmailAddress
        dataSource
            .lookup(
                emailAddress: emailAddress,
                manuallyEntered: manuallyEnteredEmail
            )
            .observe { [weak self, weak bodyFormView] result in
                guard let self = self else { return }
                let attestationError = self.dataSource.completeAssertionIfNeeded(
                    possibleError: result.error,
                    api: .consumerSessionLookup
                )
                if attestationError != nil {
                    let prefillDetails = WebPrefillDetails(email: emailAddress)
                    self.delegate?.networkingLinkSignupViewControllerDidFailAttestationVerdict(self, prefillDetails: prefillDetails)
                    return
                }

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

                        self.formView.showAndEditPhoneNumberFieldIfNeeded()
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

    func linkSignupFormViewDidUpdateFields(_ view: LinkSignupFormView) {
        adjustSaveToLinkButtonDisabledState()
    }
}
