//
//  PayoutsViewController.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/21/24.
//

import UIKit

/**
 The balance summary, the payout schedule, and a list of payouts for the connected account. It can also allow the user to perform instant or manual payouts.
 - Important: Include  `@_spi(PrivateBetaConnect)` on import to gain access to this API.
 - Seealso: [Payouts component documentation](https://docs.stripe.com/connect/supported-embedded-components/payouts?platform=ios)
 */
@_spi(PrivateBetaConnect)
@_documentation(visibility: public)
@available(iOS 15, *)
public class PayoutsViewController: UIViewController {
    private(set) var webVC: ConnectComponentWebViewController!

    @_documentation(visibility: public)
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
///  - Important: Include  `@_spi(PrivateBetaConnect)` on import to gain access to this API.
@_spi(PrivateBetaConnect)
@_documentation(visibility: public)
@available(iOS 15, *)
public protocol PayoutsViewControllerDelegate: AnyObject {

    /**
     Triggered when an error occurs loading the payouts component
     - Parameters:
       - payouts: The payouts component that errored when loading
       - error: The error that occurred when loading the component
     */
    @_documentation(visibility: public)
    func payouts(_ payouts: PayoutsViewController,
                 didFailLoadWithError error: Error)

}

@available(iOS 15, *)
@_documentation(visibility: public)
public extension PayoutsViewControllerDelegate {
    // Default implementation to make optional
    @_documentation(visibility: public)
    func payouts(_ payouts: PayoutsViewController,
                 didFailLoadWithError error: Error) { }
}
