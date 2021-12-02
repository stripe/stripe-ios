//
//  ConnectionsWebViewController.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/19/21.
//

import UIKit
import SafariServices
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
protocol ConnectionsWebViewControllerDelegate: AnyObject {

    func connectionsWebViewController(_ viewController: ConnectionsWebViewController, didFinish result: ConnectionsSheet.ConnectionsResult)
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
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
    fileprivate lazy var closeItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: Image.close.makeImage(template: false),
                                   style: .plain,
                                   target: self,
                                   action: #selector(didTapClose))

        item.tintColor = UIColor.dynamic(light: CompatibleColor.systemGray2, dark: .white)
        return item
    }()

    fileprivate lazy var backItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: Image.back_arrow.makeImage(template: false),
                                   style: .plain,
                                   target: self,
                                   action: #selector(didTapBack))
        item.tintColor = UIColor.dynamic(light: CompatibleColor.systemGray2, dark: .white)
        return item
    }()

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

        view.backgroundColor = CompatibleColor.systemBackground
        view.addAndPinSubview(webView)
        
        navigationItem.leftBarButtonItem = backItem
        navigationItem.rightBarButtonItem = closeItem
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        delegate?.connectionsWebViewController(self, didFinish: result)
    }
    
    // MARK: - Public
    
    func load() {
        webView.load(url: configuration.initialURL)
    }
    
    // MARK: - Helpers
    
    @objc
    func didTapBack() {
        webView.goBackToInitialStep()
    }
    
    @objc
    func didTapClose() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - ConnectionsWebViewDelegate

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension ConnectionsWebViewController: ConnectionsWebViewDelegate {
    
    func connectionsWebView(_ view: ConnectionsWebView, didChangeURL url: URL?) {
        // hanlde nav bar visibility and configuration
        if let host = url?.host {
            // TODO(vardges): figure out a more reliable way of doing this
            let navBarHidden = host.hasSuffix("stripe.com")
            navigationController?.setNavigationBarHidden(navBarHidden, animated: true)
            title = host
        }
        navigationItem.backBarButtonItem = webView.canGoBack ? backItem : nil

        // handle success/cancel url redirects
        if configuration.successURL == url {
            // TODO(vardges): fetch the actual link accounts
            result = .completed(linkedAccounts: [])
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
