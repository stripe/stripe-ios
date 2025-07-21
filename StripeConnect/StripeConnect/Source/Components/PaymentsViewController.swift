//
//  PaymentsViewController.swift
//  StripeConnect
//
//  Created by Torrance Yang on 7/16/25.
//

import UIKit

/**
 Displays a list of payments for the connected account. It can also allow the user to view payment details, perform refunds, and manage disputes.
 - Important: Include  `@_spi(PrivateBetaConnect)` on import to gain access to this API.
 - See also: [Payments component documentation](https://docs.stripe.com/connect/supported-embedded-components/payments?platform=ios)
 */
@_spi(PrivateBetaConnect)
@_documentation(visibility: public)
@available(iOS 15, *)
public class PaymentsViewController: UIViewController {
    private(set) var webVC: ConnectComponentWebViewController!

    @_documentation(visibility: public)
    public weak var delegate: PaymentsViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory) {
        super.init(nibName: nil, bundle: nil)
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .payments,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory
        ) { [weak self] error in
            guard let self else { return }
            delegate?.payments(self, didFailLoadWithError: error)
        }

        addChildAndPinView(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Delegate of an `PaymentsViewController`
///  - Important: Include  `@_spi(PrivateBetaConnect)` on import to gain access to this API.
@_spi(PrivateBetaConnect)
@_documentation(visibility: public)
@available(iOS 15, *)
public protocol PaymentsViewControllerDelegate: AnyObject {

    /**
     Triggered when an error occurs loading the payments component
     - Parameters:
       - payments: The payments component that errored when loading
       - error: The error that occurred when loading the component
     */
    @_documentation(visibility: public)
    func payments(_ payments: PaymentsViewController,
                 didFailLoadWithError error: Error)

}

@available(iOS 15, *)
@_documentation(visibility: public)
public extension PaymentsViewControllerDelegate {
    // Default implementation to make optional
    @_documentation(visibility: public)
    func payments(_ payments: PaymentsViewController,
                 didFailLoadWithError error: Error) { }
} 