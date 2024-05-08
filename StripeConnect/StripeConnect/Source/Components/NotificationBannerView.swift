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

    init(connectInstance: StripeConnectInstance,
         presentViewController: @escaping (UIViewController) -> Void) {
        webView = ConnectComponentWebView(
            connectInstance: connectInstance,
            componentType: "notification-banner"
        )
        super.init(frame: .zero)
        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        webView.presentPopup = presentViewController
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
