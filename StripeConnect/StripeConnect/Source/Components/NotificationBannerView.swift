//
//  NotificationBannerView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/7/24.
//

import UIKit

/**
 A notification banner that lists open risk intervention tasks and onboarding requirements that can impact certain capabilities, such as accepting payments and payouts.
 */
public class NotificationBannerView: UIView {
    let webView: ConnectComponentWebView

    lazy var heightConstraint = webView.heightAnchor.constraint(equalToConstant: 0)

    init(connectInstance: StripeConnectInstance,
         presentViewController: @escaping (UIViewController) -> Void) {

        // TODO: DRY this up with BalancesView

        webView = ConnectComponentWebView(
            connectInstance: connectInstance,
            componentType: "notification-banner"
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
