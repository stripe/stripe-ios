//
//  VerificationFlowWebView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import WebKit
@_spi(STP) import StripeCore

protocol VerificationFlowWebViewDelegate: AnyObject {
    /**
     The view's URL was changed.
     - Parameters:
       - view: The view whose URL changed.
       - url: The new URL value.
     */
    func verificationFlowWebView(_ view: VerificationFlowWebView, didChangeURL url: URL?)

    /**
     The view finished loading the web page.
     - Parameter view: The view that finished loading.
     */
    func verificationFlowWebViewDidFinishLoading(_ view: VerificationFlowWebView)

    /**
     The view received a `window.close` signal from Javascript.
     - Parameter view: The view who's sending the close action.
     */
    func verificationFlowWebViewDidClose(_ view: VerificationFlowWebView)

    /**
     The user tapped on a link that should be opened in a new target.
     - Parameters:
       - view: The view who's opening a URL.
       - url: The new URL that should be opened in a new target.
     */
    func verificationFlowWebView(_ view: VerificationFlowWebView, didOpenURLInNewTarget url: URL)
}

/**
 Basic WebView that displays a spinner while the page is loading or an error message with a "Try Again" button

 - NOTE(mludowise|RUN_MOBILESDK-120):
 This class should be marked as `@available(iOS 14.3, *)` when our CI is updated to run tests on iOS 14.
 */
final class VerificationFlowWebView: UIView {

    private struct Styling {
        static let errorViewInsets = UIEdgeInsets(top: 32, left: 16, bottom: 0, right: 16)
        static let errorViewSpacing: CGFloat = 16

        // NOTE: Computed so font is updated if UIAppearance changes
        static var errorLabelFont: UIFont {
            UIFont.preferredFont(forTextStyle: .body, weight: .medium)
        }
    }

    // Custom JS message handlers used to communicate to/from Javascript
    private enum ScriptMessageHandler: String {
        case closeWindow
    }

    // MARK: Delegates

    weak var delegate: VerificationFlowWebViewDelegate?

    // MARK: View Properties

    @objc
    private(set) lazy var webView: WKWebView = {
        // Set `allowsInlineMediaPlayback` so the camera view doesn't try to full screen.
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // Add custom JS-handler
        webView.configuration.userContentController.add(self, name: ScriptMessageHandler.closeWindow.rawValue)

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
        button.setTitle(String.Localized.tryAgain, for: .normal)
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

    private let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView()

        // TODO(mludowise|RUN_MOBILESDK-120): Remove #available clause when
        // class is marked as `@available(iOS 14.3, *)`
        if #available(iOS 13.0, *) {
            activityIndicatorView.style = .large
        }
        return activityIndicatorView
    }()

    // MARK: Instance Properties

    /// Requests the `initialURL` provided in `init`
    private let urlRequest: URLRequest

    /// Observes a change in the webView's `url` property
    private var urlObservation: NSKeyValueObservation?

    // MARK: Init

    init(initialURL: URL) {
        self.urlRequest = URLRequest(url: initialURL)
        super.init(frame: .zero)

        // TODO(mludowise|RUN_MOBILESDK-120): Remove #available clause when
        // class is marked as `@available(iOS 14.3, *)`
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        }
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

    // MARK: Accessors

    /// Loads the WebView to the `initialURL`
    func load() {
        webView.isHidden = false
        errorView.isHidden = true
        activityIndicatorView.stp_startAnimatingAndShow()
        webView.load(urlRequest)
    }

    /// Hides the WebView and displays an error message to the user with a "Try Again" button
    func displayRetryMessage() {
        activityIndicatorView.stp_stopAnimatingAndHide()
        webView.isHidden = true
        errorView.isHidden = false
    }
}

// MARK: - Private

private extension VerificationFlowWebView {
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
            self.delegate?.verificationFlowWebView(self, didChangeURL: self.webView.url)
        })
    }

    @objc
    func didTapTryAgainButton() {
        load()
    }
}

// MARK: - WKNavigationDelegate

extension VerificationFlowWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicatorView.stp_stopAnimatingAndHide()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.verificationFlowWebViewDidFinishLoading(self)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        displayRetryMessage()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        displayRetryMessage()
    }
}

// MARK: WKUIDelegate

extension VerificationFlowWebView: WKUIDelegate {
    func webViewDidClose(_ webView: WKWebView) {
        // `window.close` is called in JS
        delegate?.verificationFlowWebViewDidClose(self)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // A link is attempting to open in a new window
        // Open it in the platform's default browser
        if navigationAction.targetFrame?.isMainFrame != true,
           let url = navigationAction.request.url {
            delegate?.verificationFlowWebView(self, didOpenURLInNewTarget: url)
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension VerificationFlowWebView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageHandler = ScriptMessageHandler(rawValue: message.name) else { return }

        switch messageHandler {
        case .closeWindow:
            delegate?.verificationFlowWebViewDidClose(self)
        }
    }
}
