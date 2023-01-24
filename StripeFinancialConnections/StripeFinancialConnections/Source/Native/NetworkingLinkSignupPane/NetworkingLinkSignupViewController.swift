//
//  NetworkingLinkSignupViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/17/23.
//

import Foundation
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkSignupViewControllerDelegate: AnyObject {
    func networkingLinkSignupViewControllerDidSelectNotNow(
        _ viewController: NetworkingLinkSignupViewController
    )
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkSignupViewController: UIViewController {

    private let dataSoure: NetworkingLinkSignupDataSource
    weak var delegate: NetworkingLinkSignupViewControllerDelegate?

    private lazy var formView: NetworkingLinkSignupBodyFormView = {
        let formView = NetworkingLinkSignupBodyFormView()
        formView.delegate = self
        return formView
    }()
    private lazy var footerView: NetworkingLinkSignupFooterView = {
        return NetworkingLinkSignupFooterView(
            didSelectSaveToLink: {

            },
            didSelectNotNow: { [weak self] in
                guard let self = self else {
                    return
                }
                // TODO(kgaidis): log `click.not_now`
                // TODO(kgaidis): go to success pane
                self.delegate?.networkingLinkSignupViewControllerDidSelectNotNow(self)
            },
            didSelectURL: { [weak self] url in
                self?.didSelectURLInTextFromBackend(url)
            }
        )
    }()

    init(dataSource: NetworkingLinkSignupDataSource) {
        self.dataSoure = dataSource
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
        print(emailAddress)

        // TODO(kgaidis): first check whether a user with this `emailAddress` already exists...
        //                this is done via `startVerificationSession` call
        //                if it exists, we will log `networking.returning_consumer`
        //                and also go to `networking_save_to_link_verification`
        //                ...we also need to handle errors

        // if this user with `emailAddress` does NOT exist, we:
        // - TODO(kgaidis): show the Save to Link button

        dataSoure.analyticsClient.log(eventName: "networking.new_consumer", pane: .networkingLinkSignupPane)
        formView.showPhoneNumberTextFieldIfNeeded()
        footerView.showSaveToLinkButtonIfNeeded()
    }
}
