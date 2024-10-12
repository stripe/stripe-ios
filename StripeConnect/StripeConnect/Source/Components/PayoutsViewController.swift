//
//  PayoutsViewController.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/21/24.
//

import UIKit

/**
 The balance summary, the payout schedule, and a list of payouts for the connected account. It can also allow the user to perform instant or manual payouts.
 */
@_spi(PrivateBetaConnect)
@available(iOS 15, *)
public class PayoutsViewController: UIViewController {
    let webVC: ConnectComponentWebViewController

    public weak var delegate: PayoutsViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager,
         loadContent: Bool = true) {
        weak var weakSelf: PayoutsViewController?
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .payouts,
            didFailLoadWithError: { error in
                guard let weakSelf else { return }
                weakSelf.delegate?.payouts(weakSelf, didFailLoadWithError: error)
            },
            loadContent: loadContent
        )
        super.init(nibName: nil, bundle: nil)
        weakSelf = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = webVC.view
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
