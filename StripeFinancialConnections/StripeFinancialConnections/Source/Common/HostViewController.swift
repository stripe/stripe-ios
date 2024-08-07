//
//  HostViewController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/3/22.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol HostViewControllerDelegate: AnyObject {

    func hostViewControllerDidFinish(
        _ viewController: HostViewController,
        lastError: Error?
    )

    func hostViewController(
        _ viewController: HostViewController,
        didFetch synchronizePayload: FinancialConnectionsSynchronize
    )

    func hostViewController(
        _ hostViewController: HostViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    )
}

final class HostViewController: UIViewController {

    // MARK: - UI

    private lazy var closeItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: Image.close.makeImage(template: false),
            style: .plain,
            target: self,
            action: #selector(didTapClose)
        )
        item.tintColor = .iconDefault
        item.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        return item
    }()

    // We haven't loaded the manifest yet, so we use a nil theme to show a neutral-colored spinner.
    private let loadingView = LoadingView(frame: .zero, theme: nil)

    // MARK: - Properties

    weak var delegate: HostViewControllerDelegate?

    private let analyticsClientV1: STPAnalyticsClientProtocol
    private let clientSecret: String
    private let apiClient: FinancialConnectionsAPIClient
    private let returnURL: String?

    private var lastError: Error?

    // MARK: - Init

    init(
        analyticsClientV1: STPAnalyticsClientProtocol,
        clientSecret: String,
        returnURL: String?,
        apiClient: FinancialConnectionsAPIClient,
        delegate: HostViewControllerDelegate?
    ) {
        self.analyticsClientV1 = analyticsClientV1
        self.clientSecret = clientSecret
        self.returnURL = returnURL
        self.apiClient = apiClient
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(loadingView)
        view.backgroundColor = .customBackgroundColor
        navigationItem.rightBarButtonItem = closeItem
        loadingView.tryAgainButton.addTarget(self, action: #selector(didTapTryAgainButton), for: .touchUpInside)
        getManifest()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        loadingView.frame = view.bounds.inset(by: view.safeAreaInsets)
    }
}

// MARK: - Helpers

extension HostViewController {
    private func getManifest() {
        loadingView.errorView.isHidden = true
        loadingView.showLoading(true)

        analyticsClientV1.log(
            analytic: FinancialConnectionsSheetInitialSynchronizeStarted(clientSecret: clientSecret),
            apiClient: apiClient.backingAPIClient
        )

        apiClient
            .synchronize(
                clientSecret: clientSecret,
                returnURL: returnURL
            )
            .observe { [weak self] result in
                guard let self = self else { return }

                analyticsClientV1.log(
                    analytic: FinancialConnectionsSheetInitialSynchronizeCompleted(
                        clientSecret: clientSecret,
                        success: result.success,
                        possibleError: result.error
                    ),
                    apiClient: apiClient.backingAPIClient
                )

                switch result {
                case .success(let synchronizePayload):
                    self.lastError = nil
                    self.delegate?.hostViewController(self, didFetch: synchronizePayload)
                case .failure(let error):
                    FinancialConnectionsEvent
                        .events(fromError: error)
                        .forEach { event in
                            self.delegate?.hostViewController(self, didReceiveEvent: event)
                        }

                    self.loadingView.showLoading(false)
                    self.loadingView.errorView.isHidden = false
                    self.lastError = error
                }
            }
    }
}

// MARK: - UI Helpers

private extension HostViewController {

    @objc
    func didTapTryAgainButton() {
        getManifest()
    }

    @objc
    func didTapClose() {
        delegate?.hostViewController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(name: .cancel)
        )
        delegate?.hostViewControllerDidFinish(self, lastError: lastError)
    }
}
