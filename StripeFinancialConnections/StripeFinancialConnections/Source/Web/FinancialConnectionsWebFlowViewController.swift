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
    private var result: FinancialConnectionsSheet.Result = .canceled
    private var hasNotifiedDelegate = false

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
        loadingView.activityIndicatorView.stp_startAnimatingAndShow()
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
         In this case, we need to notify the delegate.
         */
        if #available(iOS 13.0, *) {
            notifyDelegate()
        }
    }
}

// MARK: - Helpers

extension FinancialConnectionsWebFlowViewController {

    private func notifyDelegate() {
        if hasNotifiedDelegate { return }
        self.delegate?.financialConnectionsWebFlow(viewController: self, didFinish: self.result)
        hasNotifiedDelegate = true
    }

    private func startAuthenticationSession(manifest: FinancialConnectionsSessionManifest) {
        authSessionManager = AuthenticationSessionManager(manifest: manifest, window: view.window)
        authSessionManager?
            .start()
            .observe(using: { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                   case .success(.success):
                        self.fetchSession()
                        return
                   case .success(.webCancelled):
                       self.result = .canceled
                   case .success(.nativeCancelled):
                        self.result = .canceled
                   case .failure(let error):
                        self.loadingView.errorView.isHidden = false
                        self.result = .failed(error: error)
                   }
                self.loadingView.activityIndicatorView.stp_stopAnimatingAndHide()
                self.notifyDelegate()
        })
    }

    private func fetchSession() {
        sessionFetcher
            .fetchSession()
            .observe { [weak self] (result) in
                guard let self = self else { return }
                self.loadingView.activityIndicatorView.stp_stopAnimatingAndHide()
                switch result {
                case .success(let session):
                    self.result = .completed(session: session)
                case .failure(let error):
                    self.loadingView.errorView.isHidden = false
                    self.result = .failed(error: error)
                    return
                }
                self.notifyDelegate()
            }
    }
}

// MARK: - UI Helpers

private extension FinancialConnectionsWebFlowViewController {

    @objc
    func didTapTryAgainButton() {
        fetchSession()
    }

    @objc
    func didTapClose() {
        notifyDelegate()
    }
}
