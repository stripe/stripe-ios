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
        item.tintColor = .textDisabled
        return item
    }()

    private let loadingView = LoadingView(frame: .zero)

    // MARK: - Properties

    weak var delegate: HostViewControllerDelegate?

    private let clientSecret: String
    private let apiClient: FinancialConnectionsAPIClient
    private let returnURL: String?

    private var lastError: Error?

    // MARK: - Init

    init(
        clientSecret: String,
        returnURL: String?,
        apiClient: FinancialConnectionsAPIClient,
        delegate: HostViewControllerDelegate?
    ) {
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
        loadingView.activityIndicatorView.stp_startAnimatingAndShow()
        apiClient
            .synchronize(clientSecret: clientSecret, returnURL: returnURL)
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let synchronizePayload):
                    self.lastError = nil
                    self.delegate?.hostViewController(self, didFetch: synchronizePayload)
                case .failure(let error):
                    self.loadingView.activityIndicatorView.stp_stopAnimatingAndHide()
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
        delegate?.hostViewControllerDidFinish(self, lastError: lastError)
    }
}
