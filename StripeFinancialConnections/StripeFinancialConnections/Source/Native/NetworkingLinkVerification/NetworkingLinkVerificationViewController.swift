//
//  NetworkingLinkVerificationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/7/23.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkVerificationViewControllerDelegate: AnyObject {

}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkVerificationViewController: UIViewController {

    private let dataSource: NetworkingLinkVerificationDataSource
    weak var delegate: NetworkingLinkVerificationViewControllerDelegate?

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

        let pane = PaneWithHeaderLayoutView(
            title: STPLocalizedString(
                "Sign in to Link",
                "The title of a screen where users are informed that they can sign-in-to Link." // TODO(kgaidis): modify
            ),
            subtitle: STPLocalizedString(
                "Enter the code sent to PHONE_NUMBER_HERE",  // TODO(kgaidis): modify
                "The subtitle/description of a screen where users are informed that they can sign-in-to Link."  // TODO(kgaidis): modify
            ),
            contentView: UIView(),
            footerView: nil
        )
        pane.addTo(view: view)
    }
}
