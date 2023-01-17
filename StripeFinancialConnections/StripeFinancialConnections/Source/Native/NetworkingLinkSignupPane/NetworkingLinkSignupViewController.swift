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
            contentView: UIView(),
            footerView: NetworkingLinkSignupFooterView(
                aboveCtaText: "",
                ctaText: "Not Now",
                belowCtaText: nil,
                didSelectAgree: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.delegate?.networkingLinkSignupViewControllerDidSelectNotNow(self)
                },
                didSelectURL: { _ in

                }
            )
        )
        pane.addTo(view: view)
    }
}
