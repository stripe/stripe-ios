//
//  PaymentsViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import Combine
import UIKit
import WebKit

public class PaymentsViewController: UIViewController {
    let webView: ComponentWebView

    private var cancellables: Set<AnyCancellable> = []

    init(connectInstance: StripeConnectInstance) {
        webView = ComponentWebView(
            publishableKey: connectInstance.apiClient.publishableKey ?? "",
            componentType: "payments", appearance: connectInstance.appearance,
            fetchClientSecret: connectInstance.fetchClientSecret
        )
        super.init(nibName: nil, bundle: nil)

        view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        webView.registerSubscriptions(connectInstance: connectInstance,
                                      storeIn: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
