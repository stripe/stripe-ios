//
//  DocumentsViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

import UIKit

/// Renders a list of documents available for download for the connected account.
public class DocumentsViewController: UIViewController {
    let webView: ConnectComponentWebView

    init(connectInstance: StripeConnectInstance) {
        webView = ConnectComponentWebView(
            connectInstance: connectInstance,
            componentType: "documents"
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
