//
//  PaymentDetailsViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/7/24.
//

import UIKit

/**
 Show details of a given payment and allow users to manage disputes and perform refunds.
 */
public class PaymentDetailsViewController: UIViewController {
    let webView: ConnectComponentWebView

    init(paymentId: String,
         connectInstance: StripeConnectInstance) {
        webView = ConnectComponentWebView(
            connectInstance: connectInstance,
            componentType: "payment-details"
        )
        super.init(nibName: nil, bundle: nil)
        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
        }
        webView.addMessageHandler(.init(name: "componentOnClose", didReceiveMessage: { [weak self] _ in
            self?.dismiss(animated: true)
        }))
        webView.didFinishLoading = { webView in
            webView.evaluateJavaScript("""
            component.setPayment('\(paymentId)');
            document.body.appendChild(component);
            component.setOnClose(() => {
                window.webkit.messageHandlers.componentOnClose.postMessage('');
            });
            """)
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
