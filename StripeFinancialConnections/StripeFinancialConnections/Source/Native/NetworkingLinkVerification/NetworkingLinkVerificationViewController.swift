//
//  NetworkingLinkVerificationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/7/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkVerificationViewControllerDelegate: AnyObject {

}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkVerificationViewController: UIViewController {

    private let dataSource: NetworkingLinkVerificationDataSource
    weak var delegate: NetworkingLinkVerificationViewControllerDelegate?

    private lazy var loadingView: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.color = .textDisabled
        activityIndicator.backgroundColor = .customBackgroundColor
        return activityIndicator
    }()

    init(dataSource: NetworkingLinkVerificationDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor

        showLoadingView(true)
        dataSource.startVerificationSession()
            .observe { [weak self] result in
                guard let self = self else { return }
                self.showLoadingView(false)
                switch result {
                case .success(let consumerSessionResponse):
                    self.showContent(redactedPhoneNumber: consumerSessionResponse.consumerSession.redactedPhoneNumber)
                case .failure(let error):
                    self.dataSource.analyticsClient.log(
                        eventName: "networking.verification.error",
                        parameters: [
                            // TODO(kgaidis): figure out a proper way to log this error
                            "error": "here"
                        ],
                        pane: .networkingLinkVerification
                    )
                    print(error)
                    // TODO(kgaidis): navigate to terminal error...
                }
            }
    }

    private func showContent(redactedPhoneNumber: String) {
        let pane = PaneWithHeaderLayoutView(
            title: STPLocalizedString(
                "Sign in to Link",
                "The title of a screen where users are informed that they can sign-in-to Link."
            ),
            subtitle: STPLocalizedString(
                "Enter the code sent to \(redactedPhoneNumber)",
                "The subtitle/description of a screen where users are informed that they have received a One-Type-Password (OTP) to their phone."
            ),
            contentView: UIView(),
            footerView: nil
        )
        pane.addTo(view: view)
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
}
