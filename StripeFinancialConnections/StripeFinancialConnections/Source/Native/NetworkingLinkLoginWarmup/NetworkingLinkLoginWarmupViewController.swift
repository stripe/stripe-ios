//
//  NetworkingLinkLoginWarmupViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/6/23.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

protocol NetworkingLinkLoginWarmupViewControllerDelegate: AnyObject {
    func networkingLinkLoginWarmupViewControllerDidSelectContinue(
        _ viewController: NetworkingLinkLoginWarmupViewController
    )
    func networkingLinkLoginWarmupViewController(
        _ viewController: NetworkingLinkLoginWarmupViewController,
        didSelectSkipWithManifest manifest: FinancialConnectionsSessionManifest
    )
    func networkingLinkLoginWarmupViewController(_ viewController: NetworkingLinkLoginWarmupViewController, didReceiveTerminalError error: Error)
}

final class NetworkingLinkLoginWarmupViewController: UIViewController {

    private let dataSource: NetworkingLinkLoginWarmupDataSource
    weak var delegate: NetworkingLinkLoginWarmupViewControllerDelegate?

    init(dataSource: NetworkingLinkLoginWarmupDataSource) {
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
            title: STPLocalizedString(
                "Sign in to Link",
                "The title of a screen where users are informed that they can sign-in-to Link."
            ),
            subtitle: STPLocalizedString(
                "It looks like you have a Link account. Signing in will let you quickly access your saved bank accounts.",
                "The subtitle/description of a screen where users are informed that they can sign-in-to Link."
            ),
            contentView: NetworkingLinkLoginWarmupBodyView(
                // `accountholderCustomerEmailAddress` should always be non-null, and
                // since the email is only used as a visual, it's not worth to throw an error
                // if it is null
                email: dataSource.manifest.accountholderCustomerEmailAddress ?? "you",
                didSelectContinue: { [weak self] in
                    self?.didSelectContinue()
                },
                didSelectSkip: { [weak self] in
                    self?.didSelectSkip()
                }
            ),
            footerView: nil
        )
        pane.addTo(view: view)
    }

    private func didSelectContinue() {
        dataSource.analyticsClient.log(
            eventName: "click.continue",
            pane: .networkingLinkLoginWarmup
        )
        delegate?.networkingLinkLoginWarmupViewControllerDidSelectContinue(self)
    }

    private func didSelectSkip() {
        dataSource.analyticsClient.log(
            eventName: "click.skip_sign_in",
            pane: .networkingLinkLoginWarmup
        )
        dataSource.disableNetworking()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let manifest):
                    self.delegate?.networkingLinkLoginWarmupViewController(
                        self,
                        didSelectSkipWithManifest: manifest
                    )
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "DisableNetworkingError",
                            pane: .networkingLinkLoginWarmup
                        )
                    self.delegate?.networkingLinkLoginWarmupViewController(self, didReceiveTerminalError: error)
                }
            }
    }
}
