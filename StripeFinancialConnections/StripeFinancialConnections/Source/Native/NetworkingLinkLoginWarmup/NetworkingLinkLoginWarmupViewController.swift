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

final class NetworkingLinkLoginWarmupViewController: SheetViewController {

    private let dataSource: NetworkingLinkLoginWarmupDataSource
    weak var delegate: NetworkingLinkLoginWarmupViewControllerDelegate?

    init(
        dataSource: NetworkingLinkLoginWarmupDataSource,
        panePresentationStyle: PanePresentationStyle
    ) {
        self.dataSource = dataSource
        super.init(panePresentationStyle: panePresentationStyle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: RoundedIconView(
                    image: .image(.person),
                    style: .circle
                ),
                title: STPLocalizedString(
                    "Continue with Link",
                    "The title of a screen where users are informed that they can sign-in-to Link."
                ),
                subtitle: STPLocalizedString(
                    "Use information you previously saved with your Link account.",
                    "The subtitle/description of a screen where users are informed that they can sign-in-to Link."
                ),
                contentView: NetworkingLinkLoginWarmupBodyView(
                    // `accountholderCustomerEmailAddress` should always be non-null, and
                    // since the email is only used as a visual, it's not worth to throw an error
                    // if it is null
                    email: dataSource.manifest.accountholderCustomerEmailAddress ?? "you"
                )
            ),
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: STPLocalizedString(
                        "Continue with Link",
                        "A button title. This button, when pressed, will automatically log-in the user with their e-mail to Link (one-click checkout provider)."
                    ),
                    accessibilityIdentifier: "link_continue_button",
                    action: { [weak self] in
                        self?.didSelectContinue()
                    }
                ),
                secondaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: STPLocalizedString(
                        "Not now",
                        "A button title. This button, when pressed, will skip logging in the user with their e-mail to Link (one-click checkout provider)."
                    ),
                    action: { [weak self] in
                        self?.didSelectSkip()
                    }
                )
            ).footerView
        )
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
