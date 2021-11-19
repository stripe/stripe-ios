//
//  ConnectionsWebViewController.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/19/21.
//

import UIKit
import SafariServices

protocol ConnectionsWebViewControllerDelegate: AnyObject {

    func connectionsWebViewController(_ viewController: ConnectionsWebViewController, didFinish result: ConnectionsSheet.ConnectionsResult)
}

final class ConnectionsWebViewController: UIViewController {
    
    // MARK: - Types
    
    struct Configuration {
        let initialURL: URL
        let successURL: URL
        let cancelURL: URL
    }
    
    // MARK: - Properties
    
    weak var delegate: ConnectionsWebViewControllerDelegate?
    
    fileprivate let webView: ConnectionsWebView
    fileprivate let configuration: Configuration
    fileprivate var result: ConnectionsSheet.ConnectionsResult = .canceled

    // MARK: - Init
    
    init(configuration: Configuration) {
        self.configuration = configuration
        webView = ConnectionsWebView()
        super.init(nibName: nil, bundle: nil)
        webView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        if #available(iOSApplicationExtension 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.connectionsWebViewController(self, didFinish: result)
    }
    
    // MARK: - Public
    
    func load() {
        webView.load(url: configuration.initialURL)
    }
}

// MARK: - ConnectionsWebViewDelegate

extension ConnectionsWebViewController: ConnectionsWebViewDelegate {
    
    func connectionsWebView(_ view: ConnectionsWebView, didChangeURL url: URL?) {
        if configuration.successURL == url {
            // TODO(vardges): fetch the actual link account session
            result = .completed(linkedAccountSession: LinkedAccountSession(id: "", clientSecret: "", linkedAccounts: []))
            dismiss(animated: true, completion: nil)
        } else if configuration.cancelURL == url {
            result = .canceled
            dismiss(animated: true, completion: nil)
        }
    }
    
    func connectionsWebViewDidClose(_ view: ConnectionsWebView) {
        dismiss(animated: true, completion: nil)
    }
    
    func connectionsWebView(_ view: ConnectionsWebView, didOpenURLInNewTarget url: URL) {
        present(SFSafariViewController(url: url), animated: true)
    }
}
