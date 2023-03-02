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

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkSignupViewControllerDelegate: AnyObject {
    func networkingLinkSignupViewController(
        _ viewController: NetworkingLinkSignupViewController,
        foundReturningConsumerWithSession consumerSession: ConsumerSessionData
    )
    func networkingLinkSignupViewControllerDidFinish(
        _ viewController: NetworkingLinkSignupViewController,
        withError error: Error?
    )
    func networkingLinkSignupViewController(
        _ viewController: NetworkingLinkSignupViewController,
        didReceiveTerminalError error: Error
    )
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkSignupViewController: UIViewController {

    private let dataSource: NetworkingLinkSignupDataSource
    weak var delegate: NetworkingLinkSignupViewControllerDelegate?

    private lazy var formView: NetworkingLinkSignupBodyFormView = {
        let formView = NetworkingLinkSignupBodyFormView()
        formView.delegate = self
        return formView
    }()
    private lazy var footerView: NetworkingLinkSignupFooterView = {
        return NetworkingLinkSignupFooterView(
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
                self.delegate?.networkingLinkSignupViewControllerDidFinish(self, withError: nil)
            },
            didSelectURL: { [weak self] url in
                self?.didSelectURLInTextFromBackend(url)
            }
        )
    }()

    init(dataSource: NetworkingLinkSignupDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor

        let pane = PaneWithHeaderLayoutView(
            title: "Save your account to Link",
            contentView: NetworkingLinkSignupBodyView(
                bulletPoints: [
                    FinancialConnectionsBulletPoint(
                        icon: FinancialConnectionsImage(
                            default:
                                "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--reserve-primary-3x.png"
                        ),
                        content:
                            "Connect your account faster on [Merchant] and thousands of sites."
                    ),
                    FinancialConnectionsBulletPoint(
                        icon: FinancialConnectionsImage(
                            default:
                                "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--reserve-primary-3x.png"
                        ),
                        content: "Link with Stripe encrypts your data and never shares your login details."
                    ),
                ],
                formView: formView,
                didSelectURL: { [weak self] url in
                    self?.didSelectURLInTextFromBackend(url)
                }
            ),
            footerView: footerView
        )
        pane.addTo(view: view)

        let emailAddress = dataSource.manifest.accountholderCustomerEmailAddress
        if let emailAddress = emailAddress, !emailAddress.isEmpty {
            formView.prefillEmailAddress(dataSource.manifest.accountholderCustomerEmailAddress)
        } else {
            formView.beginEditingEmailAddressField()
        }

        // TODO(kgaidis): pre-fill phone number
    }

    private func didSelectSaveToLink() {
        footerView.setIsLoading(true)
        dataSource
            .analyticsClient
            .log(
                eventName: "click.save_to_link",
                pane: .networkingLinkSignupPane
            )
        dataSource.saveToLink(
            emailAddress: formView.emailElement.emailAddressString ?? "",
            phoneNumber: formView.phoneNumberTextField.text ?? "",
            countryCode: "US"  // TODO(kgaidis): fix the country code
        )
        .observe { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.delegate?.networkingLinkSignupViewControllerDidFinish(
                    self,
                    withError: nil
                )
            case .failure(let error):
                // on error, we still go to success pane, but show a small error
                // notice above the done button of the success pane
                self.delegate?.networkingLinkSignupViewControllerDidFinish(
                    self,
                    withError: error
                )
                self.dataSource.analyticsClient.logUnexpectedError(
                    error,
                    errorName: "SaveToLinkError",
                    pane: .networkingLinkSignupPane
                )
            }
            self.footerView.setIsLoading(false)
        }
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {

    }

    private func adjustSaveToLinkButtonDisabledState() {
        let isEmailValid = formView.emailElement.validationState.isValid
        // TODO(kgaidis): add phone number validation
        footerView.enableSaveToLinkButton(isEmailValid)
    }
}

@available(iOSApplicationExtension, unavailable)
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
                            self.delegate?.networkingLinkSignupViewController(
                                self,
                                foundReturningConsumerWithSession: consumerSession
                            )
                        } else {
                            self.delegate?.networkingLinkSignupViewControllerDidFinish(
                                self,
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
                        self.formView.showPhoneNumberTextFieldIfNeeded()
                        self.footerView.showSaveToLinkButtonIfNeeded()
                        self.adjustSaveToLinkButtonDisabledState()
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

    func networkingLinkSignupBodyFormViewDidEnterInvalidEmailAddress(_ view: NetworkingLinkSignupBodyFormView) {
        adjustSaveToLinkButtonDisabledState()
    }
}
