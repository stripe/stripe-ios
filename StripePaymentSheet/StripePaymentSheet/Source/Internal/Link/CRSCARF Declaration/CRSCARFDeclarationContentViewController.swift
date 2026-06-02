//
//  CRSCARFDeclarationContentViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 4/23/26.
//

import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit
import WebKit

/// The content view of `CRSCARFDeclarationViewController`, which displays CRS/CARF declaration HTML with a confirmation button.
final class CRSCARFDeclarationContentViewController: UIViewController, BottomSheetContentViewController {

    // MARK: - BottomSheetContentViewController

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = LinkSheetNavigationBar(
            isTestMode: false,
            appearance: .default,
            brand: brand,
            shouldLogPaymentSheetAnalyticsOnDismissal: false
        )
        navigationBar.setStyle(.close(showAdditionalButton: false))
        navigationBar.delegate = self
        return navigationBar
    }()

    let requiresFullScreen: Bool = false

    // MARK: - CRSCARFDeclarationContentViewController

    private let html: String
    private let appearance: LinkAppearance
    private let brand: LinkBrand

    /// Closure called when a user confirms or cancels the declaration.
    var onResult: ((LinkController.CRSCARFDeclarationResult) -> Void)?

    /// Creates a new instance of `CRSCARFDeclarationContentViewController`.
    /// - Parameters:
    ///   - html: The declaration HTML to display.
    ///   - appearance: Determines the colors, corner radius, and height of the confirmation button.
    init(html: String, appearance: LinkAppearance, brand: LinkBrand) {
        self.html = html
        self.appearance = appearance
        self.brand = brand
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var headingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .title)
        label.textColor = .linkTextPrimary
        label.text = String.Localized.declarations
        label.numberOfLines = 0
        return label
    }()

    private lazy var declarationWebView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = [.link]
        if #unavailable(iOS 14.0) {
            configuration.preferences.javaScriptEnabled = false
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.navigationDelegate = self
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }()

    private var declarationHTML: String {
        """
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline';">
        <style>
        body {
            margin: 0;
            color: \(cssColor(for: .linkTextPrimary));
            font-family: -apple-system, sans-serif;
            font-size: \(LinkUI.font(forTextStyle: .body).pointSize)px;
            line-height: \(declarationLineHeight);
            -webkit-text-size-adjust: 100%;
        }
        p {
            margin: 0;
        }
        a {
            color: \(cssColor(for: linkPrimaryButtonColor));
        }
        </style>
        \(html)
        """
    }

    private lazy var bottomButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addAndPinSubviewToSafeArea(confirmButton, insets: .insets(amount: LinkUI.contentSpacing))
        return view
    }()

    private lazy var confirmButton = ConfirmButton.makeLinkButton(
        callToAction: .custom(title: String.Localized.agree_and_accept),
        showProcessingLabel: false,
        linkAppearance: appearance
    ) { [weak self] in
        self?.confirmButtonTapped()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(headingLabel)
        view.addSubview(declarationWebView)
        view.addSubview(bottomButtonContainer)

        NSLayoutConstraint.activate([
            headingLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: LinkUI.smallContentSpacing),
            headingLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: LinkUI.contentSpacing),
            headingLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -LinkUI.contentSpacing),

            declarationWebView.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: LinkUI.contentSpacing),
            declarationWebView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: LinkUI.contentSpacing),
            declarationWebView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -LinkUI.contentSpacing),
            declarationWebView.heightAnchor.constraint(equalToConstant: 200),
            declarationWebView.bottomAnchor.constraint(equalTo: bottomButtonContainer.topAnchor),

            bottomButtonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomButtonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        declarationWebView.loadHTMLString(declarationHTML, baseURL: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }
        declarationWebView.loadHTMLString(declarationHTML, baseURL: nil)
    }

    private func confirmButtonTapped() {
        confirmButton.update(status: .spinnerWithInteractionDisabled)
        onResult?(.confirmed)
    }

    private var linkPrimaryButtonColor: UIColor {
        appearance.colors?.primary ?? LinkUI.appearance.primaryButton.backgroundColor ?? LinkUI.appearance.colors.primary
    }

    private var declarationLineHeight: CGFloat {
        // based on the "20px" value in Figma
        20 / LinkUI.font(forTextStyle: .body).pointSize
    }

    private func cssColor(for color: UIColor) -> String {
        let resolvedColor = color.resolvedColor(with: traitCollection)
        let rgba = resolvedColor.rgba
        return "rgba(\(Int(rgba.red * 255)), \(Int(rgba.green * 255)), \(Int(rgba.blue * 255)), \(rgba.alpha))"
    }

    // MARK: - BottomSheetContentViewController

    func didTapOrSwipeToDismiss() {
        onResult?(.canceled)
    }
}

extension CRSCARFDeclarationContentViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        if #available(iOS 14.0, *) {
            preferences.allowsContentJavaScript = false
        }
        decisionHandler(policy(for: navigationAction), preferences)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(policy(for: navigationAction))
    }

    private func policy(for navigationAction: WKNavigationAction) -> WKNavigationActionPolicy {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            if ["http", "https"].contains(url.scheme?.lowercased()) {
                let safariViewController = SFSafariViewController(url: url)
                #if !os(visionOS)
                safariViewController.dismissButtonStyle = .close
                #endif
                safariViewController.modalPresentationStyle = .overFullScreen
                present(safariViewController, animated: true)
            }
            return .cancel
        }

        guard navigationAction.navigationType == .other else {
            return .cancel
        }

        if navigationAction.request.url?.scheme == "about" {
            return .allow
        }
        return .cancel
    }
}
