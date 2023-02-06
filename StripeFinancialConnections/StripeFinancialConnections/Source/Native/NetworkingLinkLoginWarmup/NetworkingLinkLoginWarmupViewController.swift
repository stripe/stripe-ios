//
//  NetworkingLinkLoginWarmupViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/6/23.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkLoginWarmupViewControllerDelegate: AnyObject {
    func networkingLinkLoginWarmupViewControllerDidSelectContinue(
        _ viewController: NetworkingLinkLoginWarmupViewController
    )
    func networkingLinkLoginWarmupViewControllerDidSelectSkip(
        _ viewController: NetworkingLinkLoginWarmupViewController
    )
    func networkingLinkLoginWarmupViewController(_ viewController: NetworkingLinkLoginWarmupViewController, didReceiveTerminalError error: Error)
}

@available(iOSApplicationExtension, unavailable)
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
                email: "kgaidis@stripe.com", // TODO(kgaidis): get email getAccountholderCustomerEmailAddress
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
        // TODO(kgaidis): disableNetworkingInSession(); disableNetworking( ... on error...do generic error (?); on success, push to 'institution_picker'
        delegate?.networkingLinkLoginWarmupViewControllerDidSelectSkip(self)
    }
}
