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

    init(connectInstance: StripeConnectInstance) {
        webView = ComponentWebView(
            connectInstance: connectInstance,
            componentType: "payments"
        )
        super.init(nibName: nil, bundle: nil)
        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
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
