//
//  ConnectionsWebView.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/18/21.
//

import UIKit
import WebKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol ConnectionsWebViewDelegate: AnyObject {
    /**
     The view's URL was changed.
     - Parameters:
       - view: The view whose URL changed.
       - url: The new URL value.
     */
    func connectionsWebView(_ view: ConnectionsWebView, didChangeURL url: URL?)

    /**
     The view received a `window.close` signal from Javascript.
     - Parameter view: The view who's sending the close action.
     */
    func connectionsWebViewDidClose(_ view: ConnectionsWebView)

    /**
     The user tapped on a link that should be opened in a new target.
     - Parameters:
       - view: The view who's opening a URL.
       - url: The new URL that should be opened in a new target.
     */
    func connectionsWebView(_ view: ConnectionsWebView, didOpenURLInNewTarget url: URL)
}

final class ConnectionsWebView: UIView {
    
    // MARK: - Types
    
    private struct Styling {
        static let errorViewInsets = UIEdgeInsets(top: 32, left: 16, bottom: 0, right: 16)
        static let errorViewSpacing: CGFloat = 16

        // NOTE: Computed so font is updated if UIAppearance changes
        static var errorLabelFont: UIFont {
            UIFont.preferredFont(forTextStyle: .body, weight: .medium)
        }
    }
    
    // MARK: Init

    init() {
        super.init(frame: .zero)

        addAndPinSubview(webView)
        installObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        urlObservation?.invalidate()
    }
    
    // MARK: - Properties
    
    weak var delegate: ConnectionsWebViewDelegate?
    
    /// Observes a change in the webView's `url` property
    private var urlObservation: NSKeyValueObservation?

    // Custom JS message handlers used to communicate to/from Javascript
    private enum ScriptMessageHandler: String {
        case closeWindow
    }
    
    // MARK: - View Properties

    @objc
    private(set) lazy var webView: WKWebView = {
        // restrict zoom
        let source: String = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            var head = document.getElementsByTagName('head')[0];
            head.appendChild(meta);
        """

        let script: WKUserScript = WKUserScript(source: source,
                                                injectionTime: .atDocumentEnd,
                                                forMainFrameOnly: true)
        let userContentController: WKUserContentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        userContentController.addUserScript(script)
        userContentController.add(self, name: ScriptMessageHandler.closeWindow.rawValue)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self

        return webView
    }()

    // MARK: - Public methods
    
    func load(url: URL) {
        webView.load(URLRequest(url: url))
    }
    
    func goBackToInitialStep() {
        guard let first = webView.backForwardList.backList.first else { return }
        webView.go(to: first)
    }
    
    var canGoBack: Bool {
        return webView.canGoBack
    }
}

// MARK: - Private

private extension ConnectionsWebView {
    func installObservers() {
        urlObservation = observe(\.webView.url, changeHandler: { [weak self] (_, _) in
            guard let self = self else { return }
            self.delegate?.connectionsWebView(self, didChangeURL: self.webView.url)
        })
    }

    @objc
    func didTapTryAgainButton() {
        webView.reload()
    }
}

// MARK: - WKUIDelegate

extension ConnectionsWebView: WKUIDelegate {

    func webViewDidClose(_ webView: WKWebView) {
        // `window.close` is called in JS
        delegate?.connectionsWebViewDidClose(self)
    }

    // TODO(vav): evaluate whether we need to respond to errors here.
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // A link is attempting to open in a new window
        // Open it in the platform's default browser
        if navigationAction.targetFrame?.isMainFrame != true,
           let url = navigationAction.request.url {
            delegate?.connectionsWebView(self, didOpenURLInNewTarget: url)
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension ConnectionsWebView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageHandler = ScriptMessageHandler(rawValue: message.name) else { return }

        switch messageHandler {
        case .closeWindow:
            delegate?.connectionsWebViewDidClose(self)
        }
    }
}
