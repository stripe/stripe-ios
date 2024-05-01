//
//  AccountOnboardingViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import Combine
import UIKit

public class AccountOnboardingViewController: UIViewController {
    let webView: ComponentWebView

    private var cancellables: Set<AnyCancellable> = []

    init(connectInstance: StripeConnectInstance) {
        // TODO: Error handle if PK is nil
        webView = ComponentWebView(
            publishableKey: connectInstance.apiClient.publishableKey ?? "",
            componentType: "account-onboarding", appearance: connectInstance.appearance,
            fetchClientSecret: connectInstance.fetchClientSecret
        ) 
        super.init(nibName: nil, bundle: nil)
        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
        }
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
