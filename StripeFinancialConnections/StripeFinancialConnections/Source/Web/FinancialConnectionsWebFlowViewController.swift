//
//  FinancialConnectionsWebFlowViewController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import UIKit
import CoreMedia
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
protocol FinancialConnectionsWebFlowViewControllerDelegate: AnyObject {

    func financialConnectionsWebFlow(
        viewController: FinancialConnectionsWebFlowViewController,
        didFinish result: FinancialConnectionsSheet.Result
    )
}

@available(iOSApplicationExtension, unavailable)
final class FinancialConnectionsWebFlowViewController : UIViewController {

    // MARK: - Properties

    weak var delegate: FinancialConnectionsWebFlowViewControllerDelegate?

    private var authSessionManager: AuthenticationSessionManager?
    private var fetchSessionError: Error?
    
    // MARK: - Waiting state view

    private lazy var continueStateView: UIView = {
        let contentView = ContinueStateView(frame: .zero)
        contentView.primaryButton.addTarget(self, action: #selector(didSelectContinueButton), for: .touchUpInside)
        return contentView
    }()
    
    /**
     Unfortunately there is a need for this state-full parameter. When we get url callback the app might not be in foreground state.
     If we then restart authentication session ASWebAuthenticationSession will fail as you can't start it in a non-foreground state.
     We keep the parameters as a state and pass on to resuming the authentication session and clearing this state.
     */
    private var unprocessedReturnURLParameters: String?
    private var subscribedToURLNotifications = false
    private var subscribedToAppActiveNotifications = false

    private let clientSecret: String
    private let apiClient: FinancialConnectionsAPIClient
    private let sessionFetcher: FinancialConnectionsSessionFetcher
    private let manifest: FinancialConnectionsSessionManifest
    private let returnURL: String?
    
    // MARK: - UI

    private lazy var closeItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: Image.close.makeImage(template: false),
                                   style: .plain,
                                   target: self,
                                   action: #selector(didTapClose))

        item.tintColor = UIColor.dynamic(light: CompatibleColor.systemGray2, dark: .white)
        return item
    }()

    private let loadingView = LoadingView(frame: .zero)

    // MARK: - Init

    init(clientSecret: String,
         apiClient: FinancialConnectionsAPIClient,
         manifest: FinancialConnectionsSessionManifest,
         sessionFetcher: FinancialConnectionsSessionFetcher,
         returnURL: String?) {
        self.clientSecret = clientSecret
        self.apiClient = apiClient
        self.manifest = manifest
        self.sessionFetcher = sessionFetcher
        self.returnURL = returnURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = closeItem
        loadingView.tryAgainButton.addTarget(self, action: #selector(didTapTryAgainButton), for: .touchUpInside)
        view.addSubview(loadingView)

        continueStateView.isHidden = true
        view.addSubview(continueStateView)
        NSLayoutConstraint.activate([
            continueStateView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            continueStateView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            continueStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        
        // start authentication session
        loadingView.errorView.isHidden = true
        startAuthenticationSession(manifest: manifest)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        loadingView.frame = view.bounds.inset(by: view.safeAreaInsets)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        /**
         On iOS13+, it is possible to swipe down on presented view controller to dismiss.
         In this case, we need to notify the delegate. Note that this opens up the issue for
         the delegtate to be called multiple times (once on success/cancel/failure, once on dismisss).
         */
        if #available(iOS 13.0, *) {
            manuallyCloseWebFlowViewController()
        }
    }
}

// MARK: - Helpers

@available(iOSApplicationExtension, unavailable)
extension FinancialConnectionsWebFlowViewController {

    private func notifyDelegate(result: FinancialConnectionsSheet.Result) {
        delegate?.financialConnectionsWebFlow(viewController: self, didFinish: result)
        delegate = nil // prevent the delegate from being called again
    }

    @available(iOSApplicationExtension, unavailable)
    private func startAuthenticationSession(manifest: FinancialConnectionsSessionManifest, additionalQueryParameters: String? = nil) {
        guard authSessionManager == nil else { return }
        loadingView.activityIndicatorView.stp_startAnimatingAndShow()
        authSessionManager = AuthenticationSessionManager(manifest: manifest, window: view.window)
        authSessionManager?
            .start(additionalQueryParameters: additionalQueryParameters)
            .observe(using: { [weak self] (result) in
                guard let self = self else { return }
                self.loadingView.activityIndicatorView.stp_stopAnimatingAndHide()
                switch result {
                   case .success(.success):
                      self.fetchSession()
                   case .success(.webCancelled):
                      self.notifyDelegate(result: .canceled)
                   case .success(.nativeCancelled):
                      self.fetchSession(userDidCancelInNative: true)
                   case .failure(let error):
                      self.notifyDelegate(result: .failed(error: error))
                   case .success(.redirect(url: let url)):
                      self.redirect(to: url)
                }
                self.authSessionManager = nil
        })
    }
    
    private func redirect(to url: URL) {
        DispatchQueue.main.async {
            self.continueStateView.isHidden = false
            self.subscribeToURLAndAppActiveNotifications()
            UIApplication.shared.open(url, options: [:], completionHandler:  nil)
        }
    }

    private func fetchSession(userDidCancelInNative: Bool = false) {
        loadingView.activityIndicatorView.stp_startAnimatingAndShow()
        loadingView.errorView.isHidden = true
        sessionFetcher
            .fetchSession()
            .observe { [weak self] (result) in
                guard let self = self else { return }
                self.loadingView.activityIndicatorView.stp_stopAnimatingAndHide()
                switch result {
                case .success(let session):
                    if userDidCancelInNative {
                        // Users can cancel the web flow even if they successfully linked
                        // accounts. As a result, we check whether they linked any
                        // before returning "cancelled."
                        if !session.accounts.data.isEmpty || session.paymentAccount != nil || session.bankAccountToken != nil {
                            self.notifyDelegate(result: .completed(session: session))
                        } else {
                            self.notifyDelegate(result: .canceled)
                        }
                    } else {
                        self.notifyDelegate(result: .completed(session: session))
                    }
                case .failure(let error):
                    self.loadingView.errorView.isHidden = false
                    self.fetchSessionError = error
                }
            }
    }
}

// MARK: - STPURLCallbackListener

@available(iOSApplicationExtension, unavailable)
extension FinancialConnectionsWebFlowViewController: STPURLCallbackListener {
    func handleURLCallback(_ url: URL) -> Bool {
        DispatchQueue.main.async {
            self.unprocessedReturnURLParameters = FinancialConnectionsWebFlowViewController.returnURLParameters(from: url)
            self.restartAuthenticationIfNeeded()
        }
        return true
    }
}


// MARK: - UI Helpers

@available(iOSApplicationExtension, unavailable)
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
            notifyDelegate(result: .failed(error: fetchSessionError))
        } else {
            notifyDelegate(result: .canceled)
        }
    }
}

// MARK: - Authentication restart helpers

@available(iOSApplicationExtension, unavailable)
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
                object: nil)
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
                for: url)
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
            object: nil)
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
    
    @objc func didSelectContinueButton() {
        startAuthenticationSession(manifest: manifest)
    }
}
