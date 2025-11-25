//
//  PMMEInfoModal.swift
//  StripePaymentSheet
//
//  Created by George Birch on 11/24/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit
import WebKit

final class PMMEInfoModal: UIViewController {

    private let infoUrl: URL
    private let style: PaymentMethodMessagingElement.Appearance.UserInterfaceStyle
    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!

    init(infoUrl: URL, style: PaymentMethodMessagingElement.Appearance.UserInterfaceStyle) {
        self.infoUrl = infoUrl
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        // override user interface style if needed
        switch style {
        case .alwaysDark:
            overrideUserInterfaceStyle = .dark
        case .alwaysLight, .flat:
            overrideUserInterfaceStyle = .light
        case .automatic:
            break
        }

        // generate theme param and background color
        // dark and flat mode background color should match loaded page while loading
        let (themeParam, backgroundColor) = switch (style, traitCollection.isDarkMode) {
        case (.alwaysLight, _), (.automatic, false): ("stripe", UIColor.white)
        case (.alwaysDark, _), (.automatic, true): ("night", UIColor(hex: 0x30313d))
        case (.flat, _): ("flat", UIColor(hex: 0xf1f1f1))
        }

        // setup url
        let queryParam = URLQueryItem(name: "theme", value: themeParam)
        guard var urlComponents = URLComponents(url: infoUrl, resolvingAgainstBaseURL: false) else {
            stpAssertionFailure("Unable to generate URL components")
            return
        }
        if urlComponents.queryItems == nil {
            urlComponents.queryItems = [queryParam]
        } else {
            urlComponents.queryItems?.append(queryParam)
        }
        guard let themedUrl = urlComponents.url else {
            stpAssertionFailure("Unable to generate themed URL")
            return
        }

        // setup view
        view.backgroundColor = backgroundColor

        // setup webview
        webView = WKWebView(frame: CGRect.zero)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addAndPinSubview(webView)

        // setup activity indicator
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        // set up close button
        let closeButton = createCloseButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        let closeButtonPadding: CGFloat = if LiquidGlassDetector.isEnabledInMerchantApp {
            PaymentSheetUI.glassPadding
        } else {
            PaymentSheetUI.defaultPadding
        }

        // constraints
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: closeButtonPadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -closeButtonPadding),
        ])

        webView.load(URLRequest(url: themedUrl))
    }

    private func createCloseButton() -> UIButton {
        let closeButton = if LiquidGlassDetector.isEnabledInMerchantApp {
            UIButton.createGlassCloseButton()
        } else {
            UIButton.createPlainCloseButton()
        }
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        return closeButton
    }

    @objc
    private func didTapCloseButton() {
        dismiss(animated: true)
    }
}

extension PMMEInfoModal: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }
}
