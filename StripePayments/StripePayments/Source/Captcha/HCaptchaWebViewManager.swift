//
//  HCaptchaWebViewManager.swift
//  HCaptcha

import Foundation
import WebKit

/** Handles comunications with the webview containing the HCaptcha challenge.
 */
internal class HCaptchaWebViewManager: NSObject {
    enum JSCommand: String {
        case execute = "execute();"
        case reset = "reset();"
    }

    typealias Log = HCaptchaLogger

    fileprivate struct Constants {
        static let BotUserAgent = "bot/2.1"
    }

    fileprivate let webViewInitSize = CGSize(width: 1, height: 1)

#if DEBUG
    /// Forces the challenge to be explicitly displayed.
    var forceVisibleChallenge = false {
        didSet {
            // Also works on iOS < 9
            webView.performSelector(
                onMainThread: Selector(("_setCustomUserAgent:")),
                with: forceVisibleChallenge ? Constants.BotUserAgent : nil,
                waitUntilDone: true
            )
        }
    }

    /// Allows validation stubbing for testing
    var shouldSkipForTests = false
#endif

    /// True if validation  token was dematerialized
    internal var resultHandled: Bool = false

    /// Sends the result message
    var completion: ((HCaptchaResult) -> Void)?

    /// Called (currently) when a challenge becomes visible
    var onEvent: ((HCaptchaEvent, Any?) -> Void)?

    /// Notifies the JS bundle has finished loading
    var onDidFinishLoading: (() -> Void)? {
        didSet {
            if didFinishLoading {
                onDidFinishLoading?()
            }
        }
    }

    /// Configures the webview for display when required
    var configureWebView: ((WKWebView) -> Void)?

    /// The dispatch token used to ensure `configureWebView` is only called once.
    var configureWebViewDispatchToken = UUID()

    /// If the HCaptcha should be reset when it errors
    var shouldResetOnError = true

    /// The JS message recoder
    fileprivate var decoder: HCaptchaDecoder!

    /// Indicates if the script has already been loaded by the `webView`
    internal var didFinishLoading = false {
        didSet {
            if didFinishLoading {
                onDidFinishLoading?()
            }
        }
    }

    /// Stop async webView configuration
    private var stopInitWebViewConfiguration = false

    /// The observer for `.UIWindowDidBecomeVisible`
    fileprivate var observer: NSObjectProtocol?

    /// Base URL for WebView
    fileprivate var baseURL: URL!

    /// Actual HTML
    fileprivate var formattedHTML: String!

    /// Keep error If it happens before validate call
    fileprivate var lastError: HCaptchaError?

    /// The webview that executes JS code
    lazy var webView: WKWebView = {
        let debug = Log.minLevel == .debug
        let webview = WKWebView(
            frame: CGRect(origin: CGPoint.zero, size: webViewInitSize),
            configuration: self.buildConfiguration()
        )
        webview.accessibilityIdentifier = "webview"
        webview.accessibilityTraits = UIAccessibilityTraits.link
        webview.isHidden = true
        if debug {
            if #available(iOS 16.4, *) {
                webview.perform(Selector(("setInspectable:")), with: true)
            }
            webview.evaluateJavaScript("navigator.userAgent") { (result, _) in
                Log.debug("WebViewManager WKWebView UserAgent: \(result ?? "nil")")
            }
        }
        Log.debug("WebViewManager WKWebView instance created")

        return webview
    }()

    /// Responsible for external link handling
    internal let urlOpener: HCaptchaURLOpener

    /**
     - parameters:
         - html: The HTML string to be loaded onto the webview
         - apiKey: The hCaptcha sitekey
         - baseURL: The URL configured with the sitekey
         - endpoint: The JS API endpoint to be loaded onto the HTML file.
         - size: Size of visible area
         - orientation: Of the widget
         - rqdata: Custom supplied challenge data
         - theme: Widget theme, value must be valid JS Object or String with brackets
     */
    init(html: String,
         apiKey: String,
         baseURL: URL,
         endpoint: URL,
         size: HCaptchaSize,
         orientation: HCaptchaOrientation,
         rqdata: String?,
         theme: String,
         urlOpener: HCaptchaURLOpener = HCapchaAppURLOpener()) {
        Log.debug("WebViewManager.init")
        self.urlOpener = urlOpener
        super.init()
        self.baseURL = baseURL
        self.decoder = HCaptchaDecoder { [weak self] result in
            self?.handle(result: result)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let debugInfo = HCaptchaDebugInfo.json
            Log.debug("WebViewManager.init after debug")
            self.formattedHTML = String(format: html, arguments: ["apiKey": apiKey,
                                                                  "endpoint": endpoint.absoluteString,
                                                                  "size": size.rawValue,
                                                                  "orientation": orientation.rawValue,
                                                                  "rqdata": rqdata ?? "",
                                                                  "theme": theme,
                                                                  "debugInfo": debugInfo,
                                                                 ])
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard !self.stopInitWebViewConfiguration else { return }

                self.setupWebview(html: self.formattedHTML, url: baseURL)
            }
        }
    }

    /**
     - parameter view: The view that should present the webview.

     Starts the challenge validation
     */
    func validate(on view: UIView) {
        Log.debug("WebViewManager.validate on: \(view)")
        resultHandled = false

#if DEBUG
        guard !shouldSkipForTests else {
            completion?(HCaptchaResult(self, token: ""))
            return
        }
#endif
        view.addSubview(webView)
        if self.didFinishLoading && (webView.bounds.size == CGSize.zero || webView.bounds.size == webViewInitSize) {
            self.doConfigureWebView()
        }

        executeJS(command: .execute)
    }

    /// Stops the execution of the webview
    func stop() {
        Log.debug("WebViewManager.stop")
        stopInitWebViewConfiguration = true
        webView.stopLoading()
        resultHandled = true
    }

    /**
     Resets the HCaptcha.

     The reset is achieved by calling `ghcaptcha.reset()` on the JS API.
     */
    func reset() {
        Log.debug("WebViewManager.reset")
        configureWebViewDispatchToken = UUID()
        stopInitWebViewConfiguration = false
        resultHandled = false
        if didFinishLoading {
            executeJS(command: .reset)
            didFinishLoading = false
        } else if let formattedHTML = self.formattedHTML {
            setupWebview(html: formattedHTML, url: baseURL)
        }
    }
}

// MARK: - Private Methods

/** Private methods for HCaptchaWebViewManager
 */
fileprivate extension HCaptchaWebViewManager {
    /**
     - returns: An instance of `WKWebViewConfiguration`

     Creates a `WKWebViewConfiguration` to be added to the `WKWebView` instance.
     */
    func buildConfiguration() -> WKWebViewConfiguration {
        let controller = WKUserContentController()
        controller.add(decoder, name: "hcaptcha")

        let conf = WKWebViewConfiguration()
        conf.userContentController = controller

        return conf
    }

    /**
     - parameter result: A `HCaptchaDecoder.Result` with the decoded message.

     Handles the decoder results received from the webview
     */
    func handle(result: HCaptchaDecoder.Result) {
        Log.debug("WebViewManager.handleResult: \(result)")

        guard !resultHandled else {
            Log.debug("WebViewManager.handleResult skip as handled")
            return
        }

        switch result {
        case .token(let token):
            completion?(HCaptchaResult(self, token: token))
        case .error(let error):
            handle(error: error)
            onEvent?(.error, error)
        case .showHCaptcha: webView.isHidden = false
        case .didLoad: didLoad()
        case .onOpen: onEvent?(.open, nil)
        case .onExpired: onEvent?(.expired, nil)
        case .onChallengeExpired: onEvent?(.challengeExpired, nil)
        case .onClose: onEvent?(.close, nil)
        case .log: break
        }
    }

    private func handle(error: HCaptchaError) {
        if error == .sessionTimeout {
            if shouldResetOnError, let view = webView.superview {
                reset()
                validate(on: view)
            } else {
                completion?(HCaptchaResult(self, error: error))
            }
        } else {
            if let completion = completion {
                completion(HCaptchaResult(self, error: error))
            } else {
                lastError = error
            }
        }
    }

    private func didLoad() {
        Log.debug("WebViewManager.didLoad")
        if completion != nil {
            executeJS(command: .execute, didLoad: true)
        }
        didFinishLoading = true
        self.doConfigureWebView()
    }

    private func doConfigureWebView() {
        Log.debug("WebViewManager.doConfigureWebView")
        if configureWebView != nil {
            DispatchQueue.once(token: configureWebViewDispatchToken) { [weak self] in
                guard let `self` = self else { return }
                self.configureWebView?(self.webView)
            }
        }
    }

    /**
     - parameters:
         - html: The embedded HTML file
         - url: The base URL given to the webview

     Adds the webview to a valid UIView and loads the initial HTML file
     */
    func setupWebview(html: String, url: URL) {
        #if os(visionOS)
        let windows = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows }
            .flatMap { $0 }
            .sorted { firstWindow, _ in firstWindow.isKeyWindow }
        let window = windows.first
        #else
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        #endif
        if let window {
            setupWebview(on: window, html: html, url: url)
        } else {
            observer = NotificationCenter.default.addObserver(
                forName: UIWindow.didBecomeVisibleNotification,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                guard let window = notification.object as? UIWindow else { return }
                guard let slf = self else { return }
                slf.setupWebview(on: window, html: html, url: url)
            }
        }
    }

    /**
     - parameters:
         - window: The window in which to add the webview
         - html: The embedded HTML file
         - url: The base URL given to the webview

     Adds the webview to a valid UIView and loads the initial HTML file
     */
    func setupWebview(on window: UIWindow, html: String, url: URL) {
        Log.debug("WebViewManager.setupWebview")
        if webView.superview == nil {
            window.addSubview(webView)
        }
        webView.loadHTMLString(html, baseURL: url)
        if webView.navigationDelegate == nil {
            webView.navigationDelegate = self
        }

        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /**
     - parameters:
         - command: The JavaScript command to be executed
         - didLoad: True if didLoad event already occured

     Executes the JS command that loads the HCaptcha challenge. This method has no effect if the webview hasn't
     finished loading.
     */
    func executeJS(command: JSCommand, didLoad: Bool = false) {
        Log.debug("WebViewManager.executeJS: \(command)")
        guard didLoad else {
            if let error = lastError {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    Log.debug("WebViewManager complete with pendingError: \(error)")

                    self.completion?(HCaptchaResult(self, error: error))
                    self.lastError = nil
                }
                if error == .networkError {
                    Log.debug("WebViewManager reloads html after \(error) error")
                    self.webView.loadHTMLString(formattedHTML, baseURL: baseURL)
                }
            }
            return
        }
        webView.evaluateJavaScript(command.rawValue) { [weak self] _, error in
            if let error = error {
                self?.decoder.send(error: .unexpected(error))
            }
        }
    }

    func executeJS(command: JSCommand) {
        executeJS(command: command, didLoad: self.didFinishLoading)
    }
}
