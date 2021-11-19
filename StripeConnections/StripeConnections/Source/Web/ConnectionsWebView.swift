//
//  ConnectionsWebView.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/18/21.
//

import UIKit
import WebKit
@_spi(STP) import StripeCore

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

    init(initialURL: URL) {
        self.urlRequest = URLRequest(url: initialURL)
        super.init(frame: .zero)

        installViews()
        installConstraints()
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
    
    /// Requests the `initialURL` provided in `init`
    private let urlRequest: URLRequest

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
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" +
            "head.appendChild(meta);"

        let script: WKUserScript = WKUserScript(source: source,
                                                injectionTime: .atDocumentEnd,
                                                forMainFrameOnly: true)
        let userContentController: WKUserContentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        userContentController.addUserScript(script)
        userContentController.add(self, name: ScriptMessageHandler.closeWindow.rawValue)

        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        return webView
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = STPLocalizedString("Unable to establish a connection.", "Error message that displays when we're unable to connect to the server.")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = Styling.errorLabelFont
        return label
    }()

    private(set) lazy var tryAgainButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.setTitle(STPLocalizedString("Try again", "Button to reload web view if we were unable to connect."), for: .normal)
        button.addTarget(self, action: #selector(didTapTryAgainButton), for: .touchUpInside)
        return button
    }()

    private let errorView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = Styling.errorViewSpacing
        return stackView
    }()

    private let activityIndicatorView = UIActivityIndicatorView()

    // MARK: - Helper Methods
    
    func displayRetryMessage() {
        activityIndicatorView.stp_stopAnimatingAndHide()
        webView.isHidden = true
        errorView.isHidden = false
    }
    
    func load() {
        webView.isHidden = false
        errorView.isHidden = true
        activityIndicatorView.stp_startAnimatingAndShow()
        webView.load(urlRequest)
    }
}

// MARK: - Private

private extension ConnectionsWebView {
    func installViews() {
        errorView.addArrangedSubview(errorLabel)
        errorView.addArrangedSubview(tryAgainButton)
        addSubview(errorView)
        addSubview(webView)
        addSubview(activityIndicatorView)
    }

    func installConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        errorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        tryAgainButton.setContentHuggingPriority(.required, for: .vertical)
        tryAgainButton.setContentCompressionResistancePriority(.required, for: .vertical)
        errorLabel.setContentHuggingPriority(.required, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            // Pin web view
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Center activity indicator
            activityIndicatorView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),

            // Pin error view to top
            errorView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Styling.errorViewInsets.top),
            errorView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Styling.errorViewInsets.left),
            errorView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Styling.errorViewInsets.right),
        ])
    }

    func installObservers() {
        urlObservation = observe(\.webView.url, changeHandler: { [weak self] (_, _) in
            guard let self = self else { return }
            self.delegate?.connectionsWebView(self, didChangeURL: self.webView.url)
        })
    }

    @objc
    func didTapTryAgainButton() {
        load()
    }
}


// MARK: - WKNavigationDelegate

extension ConnectionsWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicatorView.stp_stopAnimatingAndHide()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        displayRetryMessage()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        displayRetryMessage()
    }
}

// MARK: - WKUIDelegate

extension ConnectionsWebView: WKUIDelegate {
    func webViewDidClose(_ webView: WKWebView) {
        // `window.close` is called in JS
        delegate?.connectionsWebViewDidClose(self)
    }

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
