//
//  PaymentsViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import UIKit

/**
 Renders a transaction list for [direct charges](https://docs.stripe.com/connect/direct-charges),
 [destination charges](https://docs.stripe.com/connect/destination-charges), and
 [separate charges and transfers](https://docs.stripe.com/connect/separate-charges-and-transfers)
 on the connected account.
 */
public class PaymentsViewController: UIViewController {
    let webView: ConnectComponentWebView

    init(connectInstance: StripeConnectInstance) {
        webView = ConnectComponentWebView(
            connectInstance: connectInstance,
            componentType: "payments"
        )
        super.init(nibName: nil, bundle: nil)
        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = view.frame
        view = webView
    }
}
