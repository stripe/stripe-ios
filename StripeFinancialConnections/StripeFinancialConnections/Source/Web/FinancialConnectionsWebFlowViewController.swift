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
        item.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
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
        additionalQueryParameters: String? = nil
    ) {
        guard authSessionManager == nil else { return }
        guard let hostedAuthUrlString = manifest.hostedAuthUrl, let hostedAuthUrl = URL(string: hostedAuthUrlString) else {
            let error = FinancialConnectionsSheetError.unknown(debugDescription: "NULL or malformed `hostedAuthUrl`")
            notifyDelegateOfFailure(error: error)
            return
        }

        loadingView.showLoading(true)
        authSessionManager = AuthenticationSessionManager(manifest: manifest, window: view.window)

        let updatedHostedAuthUrl = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: hostedAuthUrl,
            isInstantDebits: manifest.isProductInstantDebits,
            elementsSessionContext: elementsSessionContext,
            prefillDetailsOverride: prefillDetailsOverride,
            additionalQueryParameters: additionalQueryParameters
        )
        authSessionManager?
            .start(hostedAuthUrl: updatedHostedAuthUrl)
            .observe(using: { [weak self] (result) in
                guard let self = self else { return }
                self.loadingView.showLoading(false)
                switch result {
                case .success(.success(let returnUrl)):
                    if manifest.isProductInstantDebits {
                        if let paymentMethod = returnUrl.extractLinkBankPaymentMethod() {
                            let instantDebitsLinkedBank = createInstantDebitsLinkedBank(
                                from: returnUrl,
                                with: paymentMethod,
                                linkAccountSessionId: manifest.id
                            )
                            self.notifyDelegateOfSuccess(result: .instantDebits(instantDebitsLinkedBank))
                        } else {
                            self.notifyDelegateOfFailure(
                                error: FinancialConnectionsSheetError.unknown(
                                    debugDescription: "Invalid payment_method returned"
                                )
                            )
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
            bankName: url.extractValue(forKey: "bank_name")?
                // backend can return "+" instead of a more-common encoding of "%20" for spaces
                .replacingOccurrences(of: "+", with: " "),
            last4: url.extractValue(forKey: "last4"),
            linkMode: elementsSessionContext?.linkMode,
            incentiveEligible: url.extractValue(forKey: "incentive_eligible").flatMap { Bool($0) } ?? false,
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
}

private extension URL {

    /// The URL contains a base64-encoded payment method. We store its values in `LinkBankPaymentMethod` so that
    /// we can parse it back in StripeCore.
    func extractLinkBankPaymentMethod() -> LinkBankPaymentMethod? {
        guard let encodedPaymentMethod = extractValue(forKey: "payment_method") else {
            return nil
        }

        guard let data = Data(base64Encoded: encodedPaymentMethod) else {
            return nil
        }

        let result: Result<LinkBankPaymentMethod, Error> = STPAPIClient.decodeResponse(
            data: data,
            error: nil,
            response: nil
        )

        return try? result.get()
    }

    func extractValue(forKey key: String) -> String? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            assertionFailure("Invalid URL")
            return nil
        }
        return components
            .queryItems?
            .first(where: { $0.name == key })?
            .value?
            .removingPercentEncoding
    }
}

// MARK: - STPURLCallbackListener

extension FinancialConnectionsWebFlowViewController: STPURLCallbackListener {
    func handleURLCallback(_ url: URL) -> Bool {
        DispatchQueue.main.async {
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
        startAuthenticationSession(manifest: manifest, additionalQueryParameters: parameters)
        unprocessedReturnURLParameters = nil
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
        return startPollingParam + "&\(fragment)"
    }
}
