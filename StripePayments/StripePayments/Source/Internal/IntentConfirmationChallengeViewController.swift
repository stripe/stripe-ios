//
//  IntentConfirmationChallengeViewController.swift
//  StripePayments
//
//  Created by Joyce Qin on 11/4/25.
//

@_spi(STP) import StripeCore
import UIKit
@preconcurrency import WebKit

/// Represents the type of intent being confirmed
enum IntentType {
    case paymentIntent(id: String)
    case setupIntent(id: String)
}

/// View controller for handling intent confirmation challenges via WebView
/// This handles the `intent_confirmation_challenge` next action type by loading
/// a Stripe-hosted web page that performs authentication via Stripe.js
@available(iOS 14.0, *)
class IntentConfirmationChallengeViewController: UIViewController {

    // MARK: - Properties
    private let publishableKey: String
    private let clientSecret: String
    private let intentType: IntentType
    private let apiClient: STPAPIClient
    private let completion: (Result<Void, Error>) -> Void

    private var webView: WKWebView!
    private var dimmedBackgroundView: UIView!
    private var closeButton: UIButton!

    // Hard-coded challenge URL
    private static let challengeHost = "b.stripecdn.com"
    private static let challengeVersion = 1
    private static let challengeURL = URL(string: "https://\(challengeHost)/mobile-confirmation-challenge/assets/index.html?v=\(challengeVersion)")!

    private let stripeJs: STPIntentActionUseStripeSDK.StripeJS?
    private let startTime: Date

    // MARK: - Initialization
    init(
        publishableKey: String,
        clientSecret: String,
        intentType: IntentType,
        apiClient: STPAPIClient,
        stripeJs: STPIntentActionUseStripeSDK.StripeJS?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        self.publishableKey = publishableKey
        self.clientSecret = clientSecret
        self.intentType = intentType
        self.apiClient = apiClient
        self.stripeJs = stripeJs
        self.completion = { result in
            completion(result)
        }
        STPAnalyticsClient.sharedClient.logIntentConfirmationChallengeStart(captchaVendorName: stripeJs?.captchaVendorName)
        self.startTime = Date()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        setupDimmedBackground()
        setupWebView()
        setupCloseButton()
        loadChallenge()
    }

    // MARK: - Setup
    private func setupDimmedBackground() {
        dimmedBackgroundView = UIView()
        dimmedBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        dimmedBackgroundView.alpha = 0 // Initially hidden

        view.addSubview(dimmedBackgroundView)

        NSLayoutConstraint.activate([
            dimmedBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmedBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Setup message handlers
        let contentController = WKUserContentController()
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "getInitParams")
        contentController.add(self, name: "onReady")
        contentController.add(self, name: "onSuccess")
        contentController.add(self, name: "onError")

        configuration.userContentController = contentController

        // Create WebView
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.customUserAgent = PaymentsSDKVariant.paymentUserAgent

        // Make webview transparent
        webView.isOpaque = false
        webView.alpha = 0

        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupCloseButton() {
        let useLiquidGlass = Self.shouldApplyLiquidGlass

        closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        let symbolConfig = UIImage.SymbolConfiguration(
            pointSize: useLiquidGlass ? 20 : 16,
            weight: useLiquidGlass ? .regular : .medium
        )
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig), for: .normal)

        if useLiquidGlass {
            let glassButtonSize: CGFloat = 44
            NSLayoutConstraint.activate([
                closeButton.widthAnchor.constraint(equalToConstant: glassButtonSize),
                closeButton.heightAnchor.constraint(equalToConstant: glassButtonSize),
            ])
            // These checks are a convenience because .glass is only available on iOS (not visionOS)
            // when compiling with XCode 26
#if compiler(>=6.2)
            #if !os(visionOS)
            if #available(iOS 26.0, visionOS 26.0, *) {
                closeButton.configuration = .glass()
            }
            #endif
#endif
        } else {
            closeButton.tintColor = .white
        }

        // Add action
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        // Accessibility
        closeButton.accessibilityLabel = String.Localized.close
        closeButton.accessibilityIdentifier = "UIButton.Close"

        // Initially hidden, will show when webview is ready
        closeButton.alpha = 0

        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
        ])
    }

    private func loadChallenge() {
        let request = URLRequest(url: Self.challengeURL)
        webView.load(request)
    }

    // break retain cycle
    private func cleanup() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "getInitParams")
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "onReady")
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "onSuccess")
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "onError")
    }

    @objc private func closeButtonTapped() {
        closeButton.isEnabled = false
        self.completion(.failure(ChallengeError.userCanceled))
        switch intentType {
        case .paymentIntent(let id):
            apiClient.cancelPaymentIntentCaptchaChallenge(paymentIntentId: id, clientSecret: clientSecret) { _, _ in }
        case .setupIntent(let id):
            apiClient.cancelSetupIntentCaptchaChallenge(setupIntentId: id, clientSecret: clientSecret) { _, _ in }
        }
        STPAnalyticsClient.sharedClient.logIntentConfirmationChallengeCanceled(duration: Date().timeIntervalSince(startTime), captchaVendorName: stripeJs?.captchaVendorName)
        cleanup()
    }

    // MARK: - Handlers
    private func handleReady() {
        STPAnalyticsClient.sharedClient.logIntentConfirmationChallengeWebViewLoaded(duration: Date().timeIntervalSince(startTime), captchaVendorName: stripeJs?.captchaVendorName)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.dimmedBackgroundView.alpha = 1.0
                self.webView.alpha = 1.0
                self.closeButton.alpha = 1.0
            }
        }
    }

    private func handleSuccess() {
        STPAnalyticsClient.sharedClient.logIntentConfirmationChallengeSuccess(duration: Date().timeIntervalSince(startTime), captchaVendorName: stripeJs?.captchaVendorName)
        cleanup()
        completion(.success(()))
    }

    private func handleError(_ error: Error) {
        STPAnalyticsClient.sharedClient.logIntentConfirmationChallengeError(error: error, duration: Date().timeIntervalSince(startTime), captchaVendorName: stripeJs?.captchaVendorName)
        cleanup()
        completion(.failure(error))
    }

    /// Validates that the message comes from the expected Stripe origin
    private func isValidMessageOrigin(_ message: WKScriptMessage) -> Bool {
        return message.frameInfo.securityOrigin.host == Self.challengeHost
    }
}

// MARK: - WKScriptMessageHandlerWithReply
@available(iOS 14.0, *)
extension IntentConfirmationChallengeViewController: WKScriptMessageHandlerWithReply {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        // Validate message origin for security
        guard isValidMessageOrigin(message) else {
            replyHandler(nil, "Invalid message origin: \(message.frameInfo.securityOrigin.host)")
            return
        }

        switch message.name {
        case "getInitParams":
            // Return the init params as a dictionary
            let params: [String: String] = [
                "clientSecret": clientSecret,
                "publishableKey": publishableKey,
            ]
            replyHandler(params, nil)

        default:
            replyHandler(nil, "Unknown message: \(message.name)")
        }
    }
}

// MARK: - WKScriptMessageHandler
@available(iOS 14.0, *)
extension IntentConfirmationChallengeViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // Validate message origin for security
        guard isValidMessageOrigin(message) else {
            stpAssertionFailure("Invalid message origin: \(message.frameInfo.securityOrigin.host)")
            return
        }

        switch message.name {
        case "onReady":
            handleReady()

        case "onSuccess":
            handleSuccess()

        case "onError":
            if let errorDict = message.body as? [String: Any],
               let errorMessage = errorDict["message"] as? String {
                let errorType = errorDict["type"] as? String ?? "unknown"
                let errorCode = errorDict["code"] as? String
                handleError(ChallengeError.webError(message: errorMessage, type: errorType, code: errorCode))
            } else {
                handleError(ChallengeError.unknownError)
            }

        default:
            stpAssertionFailure("Unknown message: \(message.name)")
        }
    }

}

// MARK: - WKNavigationDelegate
@available(iOS 14.0, *)
extension IntentConfirmationChallengeViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        // Open links (e.g., Privacy, Terms) in Safari instead of navigating within the webview
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            await UIApplication.shared.open(url)
            return .cancel
        }
        return .allow
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(ChallengeError.navigationFailed(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(ChallengeError.navigationFailed(error))
    }
}

// MARK: - Liquid Glass
@available(iOS 14.0, *)
extension IntentConfirmationChallengeViewController {
    private static var shouldApplyLiquidGlass: Bool {
        #if compiler(>=6.2)
        guard #available(iOS 26.0, *) else { return false }
        if let optedOut = Bundle.main.infoDictionary?["UIDesignRequiresCompatibility"] as? Bool, optedOut {
            return false
        }
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Errors
enum ChallengeError: LocalizedError, AnalyticLoggableError {
    case webError(message: String, type: String, code: String?)
    case navigationFailed(Error)
    case userCanceled
    case unknownError

    var analyticsErrorType: String {
        switch self {
        case .webError(_, let type, _):
            return type
        default:
            return "IntentConfirmationChallengeError"
        }
    }

    var analyticsErrorCode: String {
        switch self {
        case .webError(_, _, let code):
            return code ?? "unknown"
        default:
            return (self as NSError).code.description
        }
    }

    var additionalNonPIIErrorDetails: [String: Any] {
        switch self {
        case .webError:
            return ["from_bridge": true]
        default:
            return ["from_bridge": false]
        }
    }

    var errorDescription: String? {
        switch self {
        case .webError(let message, _, _):
            return message
        case .navigationFailed(let error):
            return "Navigation failed: \(error.localizedDescription)"
        case .userCanceled:
            return nil  // No error message for user cancellation
        case .unknownError:
            return "Unknown error."
        }
    }

}

// All duration analytics are in milliseconds
extension STPAnalyticsClient {
    func logIntentConfirmationChallengeStart(captchaVendorName: String?) {
        var params: [String: Any] = [:]
        if let captchaVendorName {
            params["captcha_vendor_name"] = captchaVendorName
        }
        log(
            analytic: GenericAnalytic(event: .intentConfirmationChallengeStart, params: params)
        )
    }

    func logIntentConfirmationChallengeSuccess(duration: TimeInterval, captchaVendorName: String?) {
        var params: [String: Any] = ["duration": duration * 1000]
        if let captchaVendorName {
            params["captcha_vendor_name"] = captchaVendorName
        }
        log(
            analytic: GenericAnalytic(event: .intentConfirmationChallengeSuccess, params: params)
        )
    }

    func logIntentConfirmationChallengeWebViewLoaded(duration: TimeInterval, captchaVendorName: String?) {
        var params: [String: Any] = ["duration": duration * 1000]
        if let captchaVendorName {
            params["captcha_vendor_name"] = captchaVendorName
        }
        log(
            analytic: GenericAnalytic(event: .intentConfirmationChallengeWebViewLoaded, params: params)
        )
    }

    func logIntentConfirmationChallengeError(error: Error, duration: TimeInterval, captchaVendorName: String?) {
        var params: [String: Any] = ["duration": duration * 1000]
        if let captchaVendorName {
            params["captcha_vendor_name"] = captchaVendorName
        }
        log(
            analytic: ErrorAnalytic(event: .intentConfirmationChallengeError, error: error, additionalNonPIIParams: params)
        )
    }

    func logIntentConfirmationChallengeCanceled(duration: TimeInterval, captchaVendorName: String?) {
        var params: [String: Any] = ["duration": duration * 1000]
        if let captchaVendorName {
            params["captcha_vendor_name"] = captchaVendorName
        }
        log(
            analytic: GenericAnalytic(event: .intentConfirmationChallengeCanceled, params: params)
        )
    }
}
