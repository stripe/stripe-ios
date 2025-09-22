//
//  PayoutsViewController.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/21/24.
//

import UIKit

@_spi(PrivateBetaConnect)
@available(iOS 15, *)
public class PayoutsViewController: UIViewController {
    private(set) var webVC: ConnectComponentWebViewController!

    public weak var delegate: PayoutsViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory) {
        super.init(nibName: nil, bundle: nil)
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .payouts,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory
        ) { [weak self] error in
            guard let self else { return }
            delegate?.payouts(self, didFailLoadWithError: error)
        }

        addChildAndPinView(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Delegate of an `PayoutsViewController`
@_spi(PrivateBetaConnect)
@available(iOS 15, *)
public protocol PayoutsViewControllerDelegate: AnyObject {

    /**
     Triggered when an error occurs loading the payouts component
     - Parameters:
       - payouts: The payouts component that errored when loading
       - error: The error that occurred when loading the component
     */
    func payouts(_ payouts: PayoutsViewController,
                 didFailLoadWithError error: Error)

}

@available(iOS 15, *)
public extension PayoutsViewControllerDelegate {
    // Default implementation to make optional
    func payouts(_ payouts: PayoutsViewController,
                 didFailLoadWithError error: Error) { }
}
