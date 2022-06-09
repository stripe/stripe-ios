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

protocol FinancialConnectionsWebFlowViewControllerDelegate: AnyObject {

    func financialConnectionsWebFlow(
        viewController: FinancialConnectionsWebFlowViewController,
        didFinish result: FinancialConnectionsSheet.Result
    )
}

final class FinancialConnectionsWebFlowViewController : UIViewController {

    // MARK: - Properties

    weak var delegate: FinancialConnectionsWebFlowViewControllerDelegate?

    private var authSessionManager: AuthenticationSessionManager?
    private var fetchSessionError: Error?

    private let clientSecret: String
    private let apiClient: FinancialConnectionsAPIClient
    private let sessionFetcher: FinancialConnectionsSessionFetcher
    private let manifest: FinancialConnectionsSessionManifest
    
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
         sessionFetcher: FinancialConnectionsSessionFetcher) {
        self.clientSecret = clientSecret
        self.apiClient = apiClient
        self.manifest = manifest
        self.sessionFetcher = sessionFetcher
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = CompatibleColor.systemBackground
        navigationItem.rightBarButtonItem = closeItem
        loadingView.tryAgainButton.addTarget(self, action: #selector(didTapTryAgainButton), for: .touchUpInside)
        view.addSubview(loadingView)

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

extension FinancialConnectionsWebFlowViewController {

    private func notifyDelegate(result: FinancialConnectionsSheet.Result) {
        delegate?.financialConnectionsWebFlow(viewController: self, didFinish: result)
        delegate = nil // prevent the delegate from being called again
    }

    private func startAuthenticationSession(manifest: FinancialConnectionsSessionManifest) {
        loadingView.activityIndicatorView.stp_startAnimatingAndShow()
        authSessionManager = AuthenticationSessionManager(manifest: manifest, window: view.window)
        authSessionManager?
            .start()
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
                   }
        })
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
                        if !session.accounts.data.isEmpty {
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
            notifyDelegate(result: .failed(error: fetchSessionError))
        } else {
            notifyDelegate(result: .canceled)
        }
    }
}

