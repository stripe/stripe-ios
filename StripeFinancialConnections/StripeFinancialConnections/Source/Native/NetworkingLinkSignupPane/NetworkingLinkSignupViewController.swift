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
        return NetworkingLinkSignupBodyFormView()
    }()
    private lazy var footerView: NetworkingLinkSignupFooterView = {
        return NetworkingLinkSignupFooterView(
            didSelectSaveToLink: {

            },
            didSelectNotNow: { [weak self] in
                guard let self = self else {
                    return
                }
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
