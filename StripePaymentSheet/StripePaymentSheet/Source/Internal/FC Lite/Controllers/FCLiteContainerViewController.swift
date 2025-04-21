//
//  FCLiteContainerViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

@_spi(STP) import StripeCore
import UIKit

class FCLiteContainerViewController: UIViewController {
    private let clientSecret: String
    private let returnUrl: URL?
    private let apiClient: FCLiteAPIClient
    private let completion: ((FinancialConnectionsSDKResult) -> Void)

    private let spinner = UIActivityIndicatorView(style: .large)
    private var errorView: ErrorView?

    private var manifest: LinkAccountSessionManifest?
    private let elementsSessionContext: ElementsSessionContext?

    private var isInstantDebits: Bool {
        manifest?.isInstantDebits == true
    }

    init(
        clientSecret: String,
        returnUrl: URL?,
        apiClient: FCLiteAPIClient,
        elementsSessionContext: ElementsSessionContext?,
        completion: @escaping ((FinancialConnectionsSDKResult) -> Void)
    ) {
        self.clientSecret = clientSecret
        self.returnUrl = returnUrl
        self.apiClient = apiClient
        self.elementsSessionContext = elementsSessionContext
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.presentationController?.delegate = self

        setupSpinner()

        Task {
            await fetchManifest()
        }
    }

    private func setupSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        guard let navigation = self.navigationController else { return }
        navigation.view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: navigation.view.safeAreaLayoutGuide.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: navigation.view.safeAreaLayoutGuide.centerYAnchor),
        ])
    }

    private func fetchManifest() async {
        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }

        do {
            let synchronize = try await apiClient.synchronize(
                clientSecret: clientSecret,
                returnUrl: returnUrl
            )
            self.manifest = synchronize.manifest
            showWebView(for: synchronize.manifest)
        } catch {
            showError()
        }
    }

    private func completeFlow(result: FCLiteAuthFlowViewController.WebFlowResult) async {
        switch result {
        case .success(let returnUrl):
            if isInstantDebits {
                createInstantDebitsLinkedBankAndComplete(from: returnUrl)
            } else {
                await fetchSessionAndComplete()
            }
        case .cancelled(let cancellationType):
            if isInstantDebits {
                completion(.cancelled)
            } else {
                // Even if a user cancelled, we check if they've connected an account.
                await fetchSessionAndComplete(cancellationType: cancellationType)
            }
        case .failure(let error):
            completion(.failed(error: error))
        }
    }

    private func fetchSessionAndComplete(
        cancellationType: FCLiteAuthFlowViewController.WebFlowResult.CancellationType? = nil
    ) async {
        DispatchQueue.main.async {
            // Pop back to root to show a loading spinner.
            self.navigationController?.popToRootViewController(animated: false)
            self.spinner.startAnimating()
        }

        do {
            let session: FinancialConnectionsSession
            if cancellationType == .cancelledOutsideWebView {
                // If the user cancelled outside the webview (i.e. swipe to dismiss),
                // we should complete the session ourselves.
                session = try await apiClient.complete(clientSecret: clientSecret)
            } else {
                // Otherwise, the session has been completed on the web side.
                session = try await apiClient.sessionReceipt(clientSecret: clientSecret)
            }

            if session.paymentAccount == nil, cancellationType != nil {
                completion(.cancelled)
                return
            }

            if let linkedBank = linkedBankFor(session: session) {
                completion(.completed(.financialConnections(linkedBank)))
            } else {
                completion(.failed(error: FCLiteError.linkedBankUnavailable))
            }
        } catch {
            completion(.failed(error: error))
        }
    }

    private func showWebView(for manifest: LinkAccountSessionManifest) {
        let authFlowVC = FCLiteAuthFlowViewController(
            manifest: manifest,
            elementsSessionContext: elementsSessionContext,
            returnUrl: returnUrl,
            onLoad: {
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                }
            },
            completion: { [weak self] result in
                guard let self else { return }
                Task {
                    await self.completeFlow(result: result)
                }
            }
        )
        navigationController?.pushViewController(authFlowVC, animated: false)
    }

    private func showError() {
        setNavigationBar(isHidden: false)

        let errorView = ErrorView()
        errorView.translatesAutoresizingMaskIntoConstraints = false

        errorView.onRetryTapped = { [weak self] in
            guard let self else { return }
            self.setNavigationBar(isHidden: true)
            self.errorView?.removeFromSuperview()
            self.errorView = nil

            Task {
                await self.fetchManifest()
            }
        }

        view.addSubview(errorView)
        self.errorView = errorView

        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func linkedBankFor(session: FinancialConnectionsSession) -> FinancialConnectionsLinkedBank? {
        switch session.paymentAccount {
        case .linkedAccount(let linkedAccount):
            return FinancialConnectionsLinkedBank(
                sessionId: session.id,
                accountId: linkedAccount.id,
                displayName: linkedAccount.displayName,
                bankName: linkedAccount.institutionName,
                last4: linkedAccount.last4,
                instantlyVerified: true
            )
        case .bankAccount(let bankAccount):
            let instantlyVerified = manifest?.bankAccountIsInstantlyVerified ?? false
            return FinancialConnectionsLinkedBank(
                sessionId: session.id,
                accountId: bankAccount.id,
                displayName: bankAccount.bankName,
                bankName: bankAccount.bankName,
                last4: bankAccount.last4,
                instantlyVerified: instantlyVerified
            )
        case .unparsable, .none:
            return nil
        }
    }

    private func createInstantDebitsLinkedBankAndComplete(from url: URL) {
        guard let paymentMethod = url.extractLinkBankPaymentMethod() else {
            completion(.failed(error: FCLiteError.linkedBankUnavailable))
            return
        }
        let linkedBank = InstantDebitsLinkedBank(
            paymentMethod: paymentMethod,
            bankName: url.extractValue(forKey: "bank_name")?
                .replacingOccurrences(of: "+", with: " "),
            last4: url.extractValue(forKey: "last4"),
            linkMode: nil,
            incentiveEligible: url.extractValue(forKey: "incentive_eligible").flatMap { Bool($0) } ?? false,
            linkAccountSessionId: manifest?.id
        )
        completion(.completed(.instantDebits(linkedBank)))
    }

    private func setNavigationBar(isHidden: Bool) {
        navigationController?.navigationBar.isHidden = isHidden
        navigationItem.rightBarButtonItem = isHidden ? nil : UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
    }

    @objc private func closeButtonTapped() {
        Task {
            await self.completeFlow(result: .cancelled(.cancelledOutsideWebView))
        }
    }
}

// MARK: UIAdaptivePresentationControllerDelegate
extension FCLiteContainerViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        showDismissConfirmation(presentedBy: presentationController.presentedViewController)
    }

    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }

    private func showDismissConfirmation(presentedBy viewController: UIViewController) {
        let alertController = UIAlertController(
            title: "Are you sure you want to exit?",
            message: "You haven't finished linking your bank account and all progress will be lost.",
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel
        ))

        alertController.addAction(UIAlertAction(
            title: "Yes, exit",
            style: .default,
            handler: { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.completeFlow(result: .cancelled(.cancelledOutsideWebView))
                }
            }
        ))

        viewController.present(alertController, animated: true)
    }
}

private extension URL {
    /// The URL contains a base64-encoded payment method. We store its values in `LinkBankPaymentMethod` so that
    /// we can parse it back in `StripeCore`.
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
