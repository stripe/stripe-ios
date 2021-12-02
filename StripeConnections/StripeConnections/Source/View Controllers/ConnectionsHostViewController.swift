//
//  ConnectionsHostViewController.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import UIKit
import AuthenticationServices
import CoreMedia
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol ConnectionsHostViewControllerDelegate: AnyObject {

    func connectionsHostViewController(
        _ viewController: ConnectionsHostViewController,
        didFinish result: ConnectionsSheet.ConnectionsResult
    )
}

final class ConnectionsHostViewController : UIViewController {

    // MARK: - Properties

    weak var delegate: ConnectionsHostViewControllerDelegate?

    fileprivate var authSession: ASWebAuthenticationSession?
    fileprivate var result: ConnectionsSheet.ConnectionsResult = .canceled

    fileprivate let linkAccountSessionClientSecret: String

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
        button.setTitle(STPLocalizedString("Try again", "Button to reload web view if we were unable to connect."), for: .normal)
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

    init(linkAccountSessionClientSecret: String) {
        self.linkAccountSessionClientSecret = linkAccountSessionClientSecret
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

extension ConnectionsHostViewController {

    fileprivate func getManifest() {
        errorView.isHidden = true
        activityIndicatorView.stp_startAnimatingAndShow()
        // TODO(vardges): Make api injectible
        STPAPIClient
            .shared
            .generateLinkAccountSessionManifest(clientSecret: self.linkAccountSessionClientSecret)
            .observe { [weak self] result in
                guard let self = self else { return }
                self.activityIndicatorView.stp_stopAnimatingAndHide()

                switch result {
                case .success(let manifest):
                    self.startAuthenticationSession(manifest: manifest)
                case .failure(let error):
                    self.errorView.isHidden = false
                    // TODO(vardges): Is it ok to propogate message here?
                    self.result = .failed(error: ConnectionsSheetError.unknown(debugDescription: error.localizedDescription))
                }

        }
    }

    fileprivate func startAuthenticationSession(manifest: LinkAccountSessionManifest) {
        guard let url = URL(string: manifest.hostedAuthUrl) else {
            result = .failed(error: ConnectionsSheetError.unknown(debugDescription: "Malformed URL"))
            dismiss(animated: true, completion: nil)
            return
        }
        authSession = ASWebAuthenticationSession(url: url,
                                                 callbackURLScheme: Constants.callbackScheme,
                                                 completionHandler: { [weak self] returnUrl, error in
                                                    guard let self = self else { return }
                                                    defer {
                                                        self.dismiss(animated: true, completion: nil)
                                                    }
                                                    if let error = error {
                                                        self.result = .failed(error: error)
                                                        return
                                                    }

                                                    guard let returnUrlString = returnUrl?.absoluteString else {
                                                        self.result = .failed(error: ConnectionsSheetError.unknown(debugDescription: "Missing return URL"))
                                                        return
                                                     }

                                                    if returnUrlString == manifest.successUrl {
                                                        // TODO: should be it's own result type not generic connections sheet
                                                        self.result = .completed(linkedAccounts: [])
                                                    } else if returnUrlString == manifest.cancelUrl {
                                                        self.result = .canceled
                                                    } else {
                                                        self.result = .failed(error: ConnectionsSheetError.unknown(debugDescription: "Unknown return URL"))
                                                    }
        })
        if #available(iOSApplicationExtension 13.0, *) {
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = true
        }

        authSession?.start()
    }
}

// MARK: - UI Helpers

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

// MARK: - ASWebAuthenticationPresentationContextProviding

extension ConnectionsHostViewController: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}

// MARK: - Constants

extension ConnectionsHostViewController {
    fileprivate enum Constants {
        static let callbackScheme = "stripe-auth"
    }

    fileprivate enum Styling {
        static let errorViewInsets = UIEdgeInsets(top: 32, left: 16, bottom: 0, right: 16)
        static let errorViewSpacing: CGFloat = 16
        static var errorLabelFont: UIFont {
            UIFont.preferredFont(forTextStyle: .body, weight: .medium)
        }
    }
}
