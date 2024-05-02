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

    init(connectInstance: StripeConnectInstance) {
        webView = ComponentWebView(
            connectInstance: connectInstance,
            componentType: "account-onboarding"
        )
        super.init(nibName: nil, bundle: nil)
        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
        }
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
