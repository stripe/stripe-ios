//
//  ConnectionsWebViewController.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/19/21.
//

import UIKit

final class ConnectionsWebViewController: UIViewController {
    
    // MARK: - Properties
    
    fileprivate let webView: ConnectionsWebView
    
    // MARK: - Init
    
    init(initialURL: URL) {
        webView = ConnectionsWebView(initialURL: initialURL)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    // MARK: - Public
    
    func load() {
        webView.load()
    }
}
