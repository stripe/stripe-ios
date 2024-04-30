//
//  PaymentsView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import Combine
import UIKit
import WebKit

public class PaymentsView: UIView {
    let webView: ComponentWebView

    private var cancellables: Set<AnyCancellable> = []

    init(connectInstance: StripeConnectInstance) {
        webView = ComponentWebView(publishableKey: connectInstance.apiClient.publishableKey ?? "",
                                   componentType: "payments",
                                   fetchClientSecret: connectInstance.fetchClientSecret)
        super.init(frame: .zero)

        addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        connectInstance.$appearance.sink { _ in

        }.store(in: &cancellables)

        connectInstance.$locale.sink { _ in

        }.store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
