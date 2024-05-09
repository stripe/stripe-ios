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

        /*
         - Setting `inline=true` makes the payment details full-screen

         - The payment-details component requires that `setPayment` be called before
           adding it to the DOM. The hosted page has special-case logic where it
           doesn't add the component to the DOM if `componentType === 'payment-details'`
           and assumes it will be added after the page has loaded from Swift.
         */
        webView.didFinishLoading = { webView in
            webView.evaluateJavaScript("""
            component.setAttribute('inline', true);
            component.setPayment('\(paymentId)');
            component.setOnClose(() => {
                window.webkit.messageHandlers.componentOnClose.postMessage('');
            });
            document.body.appendChild(component);
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
