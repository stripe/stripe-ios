//
//  PaymentsViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import Combine
import UIKit

public class PaymentsViewController: UIViewController {
    let webView: ComponentWebView

    private var cancellables: Set<AnyCancellable> = []

    init(connectInstance: StripeConnectInstance) {
        // TODO: Error handle if PK is nil
        webView = ComponentWebView(
            publishableKey: connectInstance.apiClient.publishableKey ?? "",
            componentType: "payments", appearance: connectInstance.appearance,
            fetchClientSecret: connectInstance.fetchClientSecret
        )
        super.init(nibName: nil, bundle: nil)

        webView.registerSubscriptions(connectInstance: connectInstance,
                                      storeIn: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        webView.preventRetainCycles()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = view.frame
        view = webView
    }
}
