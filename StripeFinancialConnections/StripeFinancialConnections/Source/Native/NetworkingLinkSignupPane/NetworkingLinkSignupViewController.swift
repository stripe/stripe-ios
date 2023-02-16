//
//  NetworkingLinkSignupViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/17/23.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkSignupViewControllerDelegate: AnyObject {
    func networkingLinkSignupViewController(
        _ viewController: NetworkingLinkSignupViewController,
        foundReturningConsumerWithSession consumerSession: ConsumerSessionData
    )
    func networkingLinkSignupViewControllerDidFinish(
        _ viewController: NetworkingLinkSignupViewController
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
                // TODO(kgaidis): log `click.not_now`
                // TODO(kgaidis): go to success pane
                self.delegate?.networkingLinkSignupViewControllerDidFinish(self)
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

        // TODO(kgaidis): pre-fill email
        // TODO(kgaidis): pre-fill phone number
    }

    private func didSelectSaveToLink() {
        // TODO(kgaidis): on save to link, make a network call to saveToLinkNetwork...whether SUCCESS or FAILURE...we push to success pane...
        dataSource.saveToLink(
            emailAddress: formView.emailAddressTextField.text ?? "",
            phoneNumber: formView.phoneNumberTextField.text ?? "",
            countryCode: "US"  // TODO(kgaidis): fix the country code
        )
        .observe { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.delegate?.networkingLinkSignupViewControllerDidFinish(self)
            case .failure(let error):
                // on error, we still go to success pane, but show a
                // small error notice above the done button
                self.delegate?.networkingLinkSignupViewControllerDidFinish(self)
                self.dataSource.analyticsClient.logUnexpectedError(
                    error,
                    errorName: "SaveToLinkError",
                    pane: .networkingLinkSignupPane
                )
                // TODO(kgaidis): ensure we show a small error notice after saveToLink fails
                assertionFailure("got error: \(error)")  // TODO(kgaidis): temporary to catch this
            }
        }
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {

    }
}

@available(iOSApplicationExtension, unavailable)
extension NetworkingLinkSignupViewController: NetworkingLinkSignupBodyFormViewDelegate {

    func networkingLinkSignupBodyFormViewDidEnterValidEmail(_ view: NetworkingLinkSignupBodyFormView) {
        guard let emailAddress = view.emailAddressTextField.text else {
            return
        }
        dataSource
            .lookup(emailAddress: emailAddress)
            .observe { [weak self] result in
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
                            self.delegate?.networkingLinkSignupViewController(self, foundReturningConsumerWithSession: consumerSession)
                        } else {
                            // TODO(kgaidis): show terminal error?
                        }
                    } else {
                        self.dataSource.analyticsClient.log(
                            eventName: "networking.new_consumer",
                            pane: .networkingLinkSignupPane
                        )
                        self.formView.showPhoneNumberTextFieldIfNeeded()
                        self.footerView.showSaveToLinkButtonIfNeeded()
                    }
                case .failure(let error):
                    // TODO(kgaidis): handle errors
                    self.dataSource.analyticsClient.logUnexpectedError(
                        error,
                        errorName: "LookupConsumerSessionError",
                        pane: .networkingLinkSignupPane
                    )
                }
            }
    }
}
