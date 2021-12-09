//
//  ConnectionsHostViewController.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import UIKit
import CoreMedia
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOS 12, *)
protocol ConnectionsHostViewControllerDelegate: AnyObject {

    func connectionsHostViewController(
        _ viewController: ConnectionsHostViewController,
        didFinish result: ConnectionsSheet.ConnectionsResult
    )
}

@available(iOS 12, *)
final class ConnectionsHostViewController : UIViewController {

    // MARK: - Properties

    weak var delegate: ConnectionsHostViewControllerDelegate?

    fileprivate var authSessionManager: AuthenticationSessionManager?
    fileprivate var result: ConnectionsSheet.ConnectionsResult = .canceled

    fileprivate let linkAccountSessionClientSecret: String
    fileprivate let apiClient: ConnectionsAPIClient

    // MARK: - UI

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = STPLocalizedString("Failed to connect", "Error message that displays when we're unable to connect to the server.")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = Styling.errorLabelFont
        return label
    }()

    private(set) lazy var tryAgainButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.setTitle(String.Localized.tryAgain, for: .normal)
        button.addTarget(self, action: #selector(didTapTryAgainButton), for: .touchUpInside)
        return button
    }()

    private let errorView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = Styling.errorViewSpacing
        return stackView
    }()

    private let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView()

        if #available(iOS 13.0, *) {
            activityIndicatorView.style = .large
        }
        return activityIndicatorView
    }()

    // MARK: - Init

    init(linkAccountSessionClientSecret: String,
         apiClient: ConnectionsAPIClient) {
        self.linkAccountSessionClientSecret = linkAccountSessionClientSecret
        self.apiClient = apiClient
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = CompatibleColor.systemBackground
        installViews()
        installConstraints()
        getManifest()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        delegate?.connectionsHostViewController(self, didFinish: result)
    }
}

// MARK: - Helpers

@available(iOS 12, *)
extension ConnectionsHostViewController {

    fileprivate func getManifest() {
        errorView.isHidden = true
        activityIndicatorView.stp_startAnimatingAndShow()
        apiClient
            .generateLinkAccountSessionManifest(clientSecret: self.linkAccountSessionClientSecret)
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let manifest):
                    self.startAuthenticationSession(manifest: manifest)
                case .failure(let error):
                    self.activityIndicatorView.stp_stopAnimatingAndHide()
                    self.errorView.isHidden = false
                    // TODO(vardges): Is it ok to propogate message here?
                    self.result = .failed(error: ConnectionsSheetError.unknown(debugDescription: error.localizedDescription))
                }

        }
    }

    fileprivate func startAuthenticationSession(manifest: LinkAccountSessionManifest) {
        authSessionManager = AuthenticationSessionManager(manifest: manifest, window: view.window)
        authSessionManager?
            .start()
            .observe(using: { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                   case .success(.success):
                        self.fetchLinkedAccounts()
                        return
                   case .success(.webCancelled):
                       self.result = .canceled
                   case .success(.nativeCancelled):
                        self.result = .canceled
                   case .failure(let error):
                        self.errorView.isHidden = false
                        self.result = .failed(error: error)
                   }
                self.activityIndicatorView.stp_stopAnimatingAndHide()
                self.dismiss(animated: true, completion: nil)
        })
    }

    fileprivate func fetchLinkedAccounts() {
        apiClient
            .fetchLinkedAccounts(clientSecret: linkAccountSessionClientSecret)
            .observe { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let accounts):
                    self.result = .completed(linkedAccounts: accounts)
                case .failure(let error):
                    self.errorView.isHidden = false
                    self.result = .failed(error: error)
                }
                self.activityIndicatorView.stp_stopAnimatingAndHide()
                self.dismiss(animated: true, completion: nil)
            }
    }
}

// MARK: - UI Helpers

@available(iOS 12, *)
private extension ConnectionsHostViewController {
    func installViews() {
        errorView.addArrangedSubview(errorLabel)
        errorView.addArrangedSubview(tryAgainButton)
        view.addSubview(errorView)
        view.addSubview(activityIndicatorView)
    }

    func installConstraints() {
        errorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        tryAgainButton.setContentHuggingPriority(.required, for: .vertical)
        tryAgainButton.setContentCompressionResistancePriority(.required, for: .vertical)
        errorLabel.setContentHuggingPriority(.required, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            // Center activity indicator
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),

            // Pin error view to top
            errorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Styling.errorViewInsets.left),
            errorView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: Styling.errorViewInsets.right),
        ])
    }

    @objc
    func didTapTryAgainButton() {
        getManifest()
    }
}

// MARK: - Styling

@available(iOS 12, *)
fileprivate extension ConnectionsHostViewController {
    enum Styling {
        static let errorViewInsets = UIEdgeInsets(top: 32, left: 16, bottom: 0, right: 16)
        static let errorViewSpacing: CGFloat = 8
        static var errorLabelFont: UIFont {
            UIFont.preferredFont(forTextStyle: .body, weight: .medium)
        }
    }
}
