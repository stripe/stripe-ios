//
//  BalancesView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/7/24.
//

import UIKit

/**
 The balance summary and the payout schedule. It can also allow the connected account to perform instant or manual payouts.
 */
public class BalancesView: UIView {
    let webView: ConnectComponentWebView

    lazy var heightConstraint = heightAnchor.constraint(equalToConstant: 0)

    init(connectInstance: StripeConnectInstance,
         presentViewController: @escaping (UIViewController) -> Void) {
        webView = ConnectComponentWebView(
            connectInstance: connectInstance,
            componentType: "balances"
        )
        super.init(frame: .zero)
        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightConstraint
        ])
        webView.presentPopup = presentViewController

        webView.didFinishLoading = { [weak self] webView in
            Task { @MainActor in
                do {
                    let _ = try await webView.evaluateJavaScript("document.readyState")
                    let h = try await webView.evaluateJavaScript("document.body.scrollHeight")
                    if let height = h as? CGFloat {
                        self?.heightConstraint.constant = height
                    }
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
