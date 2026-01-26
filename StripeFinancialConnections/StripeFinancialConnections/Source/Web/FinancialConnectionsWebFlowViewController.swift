//
//  FinancialConnectionsWebFlowViewController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import CoreMedia
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol FinancialConnectionsWebFlowViewControllerDelegate: AnyObject {

    func webFlowViewController(
        _ viewController: FinancialConnectionsWebFlowViewController,
        didFinish result: HostControllerResult
    )

    func webFlowViewController(
        _ webFlowViewController: UIViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    )
}

final class FinancialConnectionsWebFlowViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: FinancialConnectionsWebFlowViewControllerDelegate?

    private var authSessionManager: AuthenticationSessionManager?
    private var fetchSessionError: Error?

    // MARK: - Waiting state view

    private lazy var continueStateView: UIView = {
        let continueStateViews = ContinueStateViews(
            institutionImageUrl: nil,
            appearance: manifest.appearance,
            didSelectContinue: { [weak self] in
                guard let self else { return }
                if let url = self.lastOpenedNativeURL {
                    self.redirect(to: url)
                } else {
                    self.startAuthenticationSession(manifest: self.manifest)
                }
            },
            didSelectCancel: nil
        )
        return PaneLayoutView(
            contentView: continueStateViews.contentView,
            footerView: continueStateViews.footerView
        ).createView()
    }()

    /**
     Unfortunately there is a need for this state-full parameter. When we get url callback the app might not be in foreground state.
     If we then restart authentication session ASWebAuthenticationSession will fail as you can't start it in a non-foreground state.
     We keep the parameters as a state and pass on to resuming the authentication session and clearing this state.
     */
    private var unprocessedReturnURLParameters: String?
    /// The hosted auth URL extracted from the callback URL, used when restarting the webview after app-to-app auth.
    /// This URL may contain a different (consumer) publishable key than the original manifest URL.
    private var unprocessedHostedAuthUrl: URL?
    private var subscribedToURLNotifications = false
    private var subscribedToAppActiveNotifications = false
    private var lastOpenedNativeURL: URL?

    private let clientSecret: String
    private let apiClient: any FinancialConnectionsAPI
    private let sessionFetcher: FinancialConnectionsSessionFetcher
    private let manifest: FinancialConnectionsSessionManifest
    private let returnURL: String?
    private let elementsSessionContext: ElementsSessionContext?
    private let prefillDetailsOverride: WebPrefillDetails?

    // MARK: - UI

    private lazy var closeItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: Image.close.makeImage(template: false),
            style: .plain,
            target: self,
            action: #selector(didTapClose)
        )
        item.tintColor = FinancialConnectionsAppearance.Colors.icon
        item.applyFinancialConnectionsCloseButtonEdgeInsets()
        return item
    }()

    // Use nil theme so the spinner view doesn't flash to the theme's color before launching the webview.
    private let loadingView = LoadingView(frame: .zero, appearance: nil)

    // MARK: - Init

    init(
        clientSecret: String,
        apiClient: any FinancialConnectionsAPI,
        manifest: FinancialConnectionsSessionManifest,
        sessionFetcher: FinancialConnectionsSessionFetcher,
        returnURL: String?,
        elementsSessionContext: ElementsSessionContext?,
        prefillDetailsOverride: WebPrefillDetails?
    ) {
        self.clientSecret = clientSecret
        self.apiClient = apiClient
        self.manifest = manifest
        self.sessionFetcher = sessionFetcher
        self.returnURL = returnURL
        self.elementsSessionContext = elementsSessionContext
        self.prefillDetailsOverride = prefillDetailsOverride
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = FinancialConnectionsAppearance.Colors.background
        navigationItem.rightBarButtonItem = closeItem
        loadingView.tryAgainButton.addTarget(self, action: #selector(didTapTryAgainButton), for: .touchUpInside)
        view.addSubview(loadingView)

        continueStateView.isHidden = true
        view.addSubview(continueStateView)
        view.addAndPinSubviewToSafeArea(continueStateView)

        // start authentication session
        loadingView.errorView.isHidden = true
        startAuthenticationSession(manifest: manifest)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        loadingView.frame = view.bounds.inset(by: view.safeAreaInsets)
    }
}

// MARK: - Helpers

extension FinancialConnectionsWebFlowViewController {

    private func notifyDelegate(result: HostControllerResult) {
        let updatedResult = result.updateWith(manifest)
        delegate?.webFlowViewController(self, didFinish: updatedResult)
        delegate = nil  // prevent the delegate from being called again
    }

    private func startAuthenticationSession(
        manifest: FinancialConnectionsSessionManifest,
        additionalQueryParameters: String? = nil,
        hostedAuthUrlOverride: URL? = nil
    ) {
        guard authSessionManager == nil else { return }
        guard let hostedAuthUrlString = manifest.hostedAuthUrl, let manifestHostedAuthUrl = URL(string: hostedAuthUrlString) else {
            let error = FinancialConnectionsSheetError.unknown(debugDescription: "NULL or malformed `hostedAuthUrl`")
            notifyDelegateOfFailure(error: error)
            return
        }

        // Use the override URL if provided (contains consumer's publishable key after Link login),
        // otherwise fall back to the manifest's hosted auth URL (merchant's publishable key).
        let hostedAuthUrl = hostedAuthUrlOverride ?? manifestHostedAuthUrl

        // #region agent log
        print("**** [H3] startAuthenticationSession - manifestHostedAuthUrl: \(hostedAuthUrlString)")
        print("**** [H3] startAuthenticationSession - hostedAuthUrlOverride: \(hostedAuthUrlOverride?.absoluteString ?? "nil")")
        print("**** [H3] startAuthenticationSession - additionalQueryParameters: \(additionalQueryParameters ?? "nil")")
        // #endregion

        loadingView.showLoading(true)
        authSessionManager = AuthenticationSessionManager(manifest: manifest, window: view.window)

        let updatedHostedAuthUrl = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: hostedAuthUrl,
            isInstantDebits: manifest.isProductInstantDebits,
            hasExistingAccountholderToken: manifest.accountholderToken != nil,
            elementsSessionContext: elementsSessionContext,
            prefillDetailsOverride: prefillDetailsOverride,
            additionalQueryParameters: additionalQueryParameters
        )
        // #region agent log
        print("**** [H4] startAuthenticationSession - baseHostedAuthUrl: \(hostedAuthUrl.absoluteString)")
        print("**** [H4] startAuthenticationSession - updatedHostedAuthUrl: \(updatedHostedAuthUrl.absoluteString)")
        // #endregion
        authSessionManager?
            .start(hostedAuthUrl: updatedHostedAuthUrl)
            .observe(using: { [weak self] (result) in
                guard let self = self else { return }
                self.loadingView.showLoading(false)
                switch result {
                case .success(.success(let returnUrl)):
                    if manifest.isProductInstantDebits {
                        do {
                            if let paymentMethod = try returnUrl.extractLinkBankPaymentMethod() {
                                let instantDebitsLinkedBank = createInstantDebitsLinkedBank(
                                    from: returnUrl,
                                    with: paymentMethod,
                                    linkAccountSessionId: manifest.id
                                )
                                self.notifyDelegateOfSuccess(result: .instantDebits(instantDebitsLinkedBank))
                            } else if let linkedAccountId = returnUrl.extractQueryValue(forKey: "linked_account") {
                                self.notifyDelegateOfSuccess(result: .linkedAccount(id: linkedAccountId))
                            } else {
                                let error = FinancialConnectionsSheetError.unknown(
                                    debugDescription: "Missing payment_method or linked_account in return URL"
                                )
                                throw error
                            }
                        } catch {
                            self.logInstantDebitsCompletionFailure(error: error)
                            self.notifyDelegateOfFailure(error: error)
                        }
                    } else {
                        self.fetchSession()
                    }
                case .success(.webCancelled):
                    if manifest.isProductInstantDebits {
                        self.notifyDelegateOfCancel()
                    } else {
                        self.fetchSession(webCancelled: true)
                    }
                case .success(.nativeCancelled):
                    if manifest.isProductInstantDebits {
                        self.notifyDelegateOfCancel()
                    } else {
                        self.fetchSession(userDidCancelInNative: true)
                    }
                case .failure(let error):
                    self.notifyDelegateOfFailure(error: error)
                case .success(.redirect(url: let url)):
                    self.redirect(to: url)
                }
                self.authSessionManager = nil
            })
    }

    private func createInstantDebitsLinkedBank(
        from url: URL,
        with paymentMethod: LinkBankPaymentMethod,
        linkAccountSessionId: String
    ) -> InstantDebitsLinkedBank {
        return InstantDebitsLinkedBank(
            paymentMethod: paymentMethod,
            bankName: url.extractQueryValue(forKey: "bank_name")?
                // backend can return "+" instead of a more-common encoding of "%20" for spaces
                .replacingOccurrences(of: "+", with: " "),
            last4: url.extractQueryValue(forKey: "last4"),
            linkMode: elementsSessionContext?.linkMode,
            incentiveEligible: url.extractQueryValue(forKey: "incentive_eligible").flatMap { Bool($0) } ?? false,
            linkAccountSessionId: linkAccountSessionId
        )
    }

    private func redirect(to url: URL) {
        DispatchQueue.main.async {
            self.continueStateView.isHidden = false
            self.subscribeToURLAndAppActiveNotifications()
            self.lastOpenedNativeURL = url
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func fetchSession(userDidCancelInNative: Bool = false, webCancelled: Bool = false) {
        loadingView.showLoading(true)
        loadingView.errorView.isHidden = true
        sessionFetcher
            .fetchSession()
            .observe { [weak self] (result) in
                guard let self = self else { return }
                self.loadingView.showLoading(false)
                switch result {
                case .success(let session):
                    if userDidCancelInNative {
                        // Users can cancel the web flow even if they successfully linked
                        // accounts. As a result, we check whether they linked any
                        // before returning "cancelled."
                        if !session.accounts.data.isEmpty || session.paymentAccount != nil || session.bankAccountToken != nil {
                            self.notifyDelegateOfSuccess(result: .financialConnections(session))
                        } else {
                            self.notifyDelegateOfCancel()
                        }
                    } else if webCancelled {
                        if session.status == .cancelled && session.statusDetails?.cancelled?.reason == .customManualEntry {
                            self.notifyDelegate(result: .failed(error: FinancialConnectionsCustomManualEntryRequiredError()))
                        } else {
                            self.notifyDelegateOfCancel()
                        }
                    } else {
                        self.notifyDelegateOfSuccess(result: .financialConnections(session))
                    }
                case .failure(let error):
                    self.loadingView.errorView.isHidden = false
                    self.fetchSessionError = error
                }
            }
    }

    private func notifyDelegateOfSuccess(result: HostControllerResult.Completed) {
        let session: StripeAPI.FinancialConnectionsSession?
        if case .financialConnections(let wrappedSession) = result {
            session = wrappedSession
        } else {
            session = nil
        }
        delegate?.webFlowViewController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(
                name: .success,
                metadata: FinancialConnectionsEvent.Metadata(
                    manualEntry: session?.paymentAccount?.isManualEntry ?? false
                )
            )
        )
        notifyDelegate(result: .completed(result))
    }

    private func notifyDelegateOfCancel() {
        delegate?.webFlowViewController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(name: .cancel)
        )
        notifyDelegate(result: .canceled)
    }

    // all failures except custom manual entry failure
    private func notifyDelegateOfFailure(error: Error) {
        FinancialConnectionsEvent
            .events(fromError: error)
            .forEach { event in
                delegate?.webFlowViewController(self, didReceiveEvent: event)
            }

        notifyDelegate(result: .failed(error: error))
    }

    private func logInstantDebitsCompletionFailure(error: Error) {
        let errorAnalytic = ErrorAnalytic(
            event: .instantDebitsCompletionFailed,
            error: error,
            additionalNonPIIParams: [
                "flow": "fc_sdk_web",
            ]
        )
        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
    }
}

// MARK: - STPURLCallbackListener

extension FinancialConnectionsWebFlowViewController: STPURLCallbackListener {
    func handleURLCallback(_ url: URL) -> Bool {
        DispatchQueue.main.async {
            // #region agent log
            print("**** [H1] handleURLCallback - url: \(url.absoluteString)")
            print("**** [H1] handleURLCallback - fragment: \(url.fragment ?? "nil")")
            // #endregion

            // Extract hostedAuthUrl from the callback URL fragment if present.
            // This URL contains the consumer's publishable key after Link login.
            if let fragment = url.fragment {
                let fragmentComponents = URLComponents(string: "?" + fragment)
                if let hostedAuthUrlEncoded = fragmentComponents?.queryItems?.first(where: { $0.name == "hostedAuthUrl" })?.value,
                   let hostedAuthUrl = URL(string: hostedAuthUrlEncoded) {
                    self.unprocessedHostedAuthUrl = hostedAuthUrl
                    // #region agent log
                    print("**** [H1] handleURLCallback - extracted hostedAuthUrl: \(hostedAuthUrl.absoluteString)")
                    // #endregion
                }
            }

            self.unprocessedReturnURLParameters = FinancialConnectionsWebFlowViewController.returnURLParameters(
                from: url
            )
            self.restartAuthenticationIfNeeded()
        }
        return true
    }
}

// MARK: - UI Helpers

private extension FinancialConnectionsWebFlowViewController {

    @objc
    private func didTapTryAgainButton() {
        fetchSession()
    }

    @objc
    private func didTapClose() {
        manuallyCloseWebFlowViewController()
    }

    private func manuallyCloseWebFlowViewController() {
        if let fetchSessionError = fetchSessionError {
            notifyDelegateOfFailure(error: fetchSessionError)
        } else {
            notifyDelegate(result: .canceled)
        }
    }
}

// MARK: - Authentication restart helpers

private extension FinancialConnectionsWebFlowViewController {

    private func restartAuthenticationIfNeeded() {
        dispatchPrecondition(condition: .onQueue(.main))

        guard UIApplication.shared.applicationState == .active, let parameters = unprocessedReturnURLParameters else {
            /**
             When we get url callback the app might not be in foreground state.
             If we then restart authentication session ASWebAuthenticationSession will fail as you can't start it in a non-foreground state.
             */
            return
        }

        // When we have a hostedAuthUrl override (consumer's URL), don't pass additional parameters.
        // The backend's hostedAuthUrl is designed to be complete and self-sufficient.
        // Adding startPolling/authSessionId may confuse the consumer's session context.
        let additionalParams = unprocessedHostedAuthUrl != nil ? nil : parameters

        // #region agent log
        print("**** [H10] restartAuthenticationIfNeeded - hasHostedAuthUrlOverride: \(unprocessedHostedAuthUrl != nil)")
        print("**** [H10] restartAuthenticationIfNeeded - using additionalParams: \(additionalParams ?? "nil")")
        // #endregion

        startAuthenticationSession(
            manifest: manifest,
            additionalQueryParameters: additionalParams,
            hostedAuthUrlOverride: unprocessedHostedAuthUrl
        )
        unprocessedReturnURLParameters = nil
        unprocessedHostedAuthUrl = nil
        lastOpenedNativeURL = nil
        continueStateView.isHidden = true
        unsubscribeFromNotifications()
    }

    private func subscribeToURLAndAppActiveNotifications() {
        dispatchPrecondition(condition: .onQueue(.main))

        subscribeToURLNotifications()
        if !subscribedToAppActiveNotifications {
            subscribedToAppActiveNotifications = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleDidBecomeActiveNotification),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }

    private func subscribeToURLNotifications() {
        dispatchPrecondition(condition: .onQueue(.main))

        guard let returnURL = returnURL, let url = URL(string: returnURL) else {
            return
        }
        if !subscribedToURLNotifications {
            subscribedToURLNotifications = true
            STPURLCallbackHandler.shared().register(
                self,
                for: url
            )
        }
    }

    @objc func handleDidBecomeActiveNotification() {
        DispatchQueue.main.async {
            self.restartAuthenticationIfNeeded()
        }
    }

    private func unsubscribeFromNotifications() {
        dispatchPrecondition(condition: .onQueue(.main))

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        STPURLCallbackHandler.shared().unregisterListener(self)
        subscribedToURLNotifications = false
        subscribedToAppActiveNotifications = false
    }

    private static func returnURLParameters(from incoming: URL) -> String {
        let startPollingParam = "&startPolling=true"
        guard let fragment = incoming.fragment else {
            return startPollingParam
        }

        // Strip certain parameters from the fragment:
        // - hostedAuthUrl: handled separately as the base URL
        // - code: this is the OAuth result code from the bank, not needed for the web client restart
        var fragmentComponents = URLComponents(string: "?" + fragment)
        fragmentComponents?.queryItems?.removeAll(where: { $0.name == "hostedAuthUrl" || $0.name == "code" })
        let filteredFragment = fragmentComponents?.query ?? fragment

        let result = startPollingParam + "&\(filteredFragment)"
        // #region agent log
        print("**** [H2] returnURLParameters - original fragment: \(fragment)")
        print("**** [H2] returnURLParameters - filtered fragment: \(filteredFragment)")
        print("**** [H2] returnURLParameters - result: \(result)")
        // #endregion
        return result
    }
}
