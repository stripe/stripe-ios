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

    lazy var heightConstraint = webView.heightAnchor.constraint(equalToConstant: 0)

    init(connectInstance: StripeConnectInstance,
         presentViewController: @escaping (UIViewController) -> Void) {

        // TODO: DRY this up with NotificationBannerView

        webView = ConnectComponentWebView(
            connectInstance: connectInstance,
            componentType: "balances"
        )
        super.init(frame: .zero)
        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            heightConstraint,
        ])
        webView.presentPopup = presentViewController
        webView.scrollView.isScrollEnabled = false
        webView.addMessageHandler(.init(name: "updateHeight", didReceiveMessage: { [weak heightConstraint] message in
            if let height = message.body as? CGFloat {
                heightConstraint?.constant = height
            }
        }))

        webView.didFinishLoading = { webView in
            /*
             Set a timer to update the height every 100ms

             NOTE: It would be better if we could observe document.body and get
             updates any time it changes, but that doesn't consistently work.
             */
            webView.evaluateJavaScript("""
            setInterval(() => {
                window.webkit.messageHandlers.updateHeight.postMessage(document.body.scrollHeight);
            }, 100);
            """)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
