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
public class PayoutsViewController: UIViewController {
    let webView: ConnectComponentWebView
    
    public weak var delegate: PayoutsViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager) {
        webView = ConnectComponentWebView(
            componentManager: componentManager,
            componentType: .payouts
        )
        super.init(nibName: nil, bundle: nil)
        webView.addMessageHandler(OnLoadErrorMessageHandler { [weak self] value in
            guard let self else { return }
            self.delegate?.payoutsLoadDidFail(self, withError: value.error.connectEmbedError)
        })
        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = webView
    }
}

/// Delegate of an `PayoutsViewController`
@_spi(PrivateBetaConnect)
public protocol PayoutsViewControllerDelegate: AnyObject {

    /**
     Triggered when an error occurs loading the payouts component
     - Parameters:
       - payouts: The payouts component that errored when loading
       - error: The error that occurred when loading the component
     */
    func payoutsLoadDidFail(_ payouts: PayoutsViewController,
                            withError error: Error)

}

public extension PayoutsViewControllerDelegate {
    // Default implementation to make optional
    func payoutsLoadDidFail(_ payouts: PayoutsViewController,
                            withError error: Error) { }
}

