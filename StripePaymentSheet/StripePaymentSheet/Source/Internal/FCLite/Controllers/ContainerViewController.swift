//
//  ContainerViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-12.
//

@_spi(STP) import StripeCore
import UIKit

class ContainerViewController: UIViewController {
    private let clientSecret: String
    private let returnUrl: URL
    private let apiClient: FCLiteAPIClient
    private let completion: ((FinancialConnectionsSDKResult) -> Void)

    private let spinner = UIActivityIndicatorView(style: .large)

    private var manifest: LinkAccountSessionManifest?
    private var authFlowViewController: AuthFlowViewController?

    private var isInstantDebits: Bool {
        manifest?.isInstantDebits == true
    }

    init(
        clientSecret: String,
        returnUrl: URL,
        apiClient: FCLiteAPIClient,
        completion: @escaping ((FinancialConnectionsSDKResult) -> Void)
    ) {
        self.clientSecret = clientSecret
        self.returnUrl = returnUrl
        self.apiClient = apiClient
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
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
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

            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        } catch {
            showError(error)

            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }
    }

    private func completeFlow(result: AuthFlowViewController.WebFlowResult) async {
        switch result {
        case .success(let returnUrl):
            if isInstantDebits {
                createInstantDebitsLinkedBankAndComplete(from: returnUrl)
            } else {
                await fetchSessionAndComplete()
            }
        case .cancelled:
            if isInstantDebits {
                completion(.cancelled)
            } else {
                await fetchSessionAndComplete(userCancelled: true)
            }
        case .failure(let error):
            completion(.failed(error: error))
        }
    }

    private func fetchSessionAndComplete(userCancelled: Bool = false) async {
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: false)
            self.spinner.startAnimating()
        }

        do {
            let session = try await apiClient.sessionReceipt(clientSecret: clientSecret)
            if session.paymentAccount == nil, userCancelled {
                completion(.cancelled)
                return
            }

            if let linkedBank = linkedBankFor(session: session) {
                completion(.completed(.financialConnections(linkedBank)))
            } else {
                completion(.failed(error: FCLiteError.linkedBankUnavailable))
            }

            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        } catch {
            completion(.failed(error: error))

            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }
    }

    private func showWebView(for manifest: LinkAccountSessionManifest) {
        let authFlowVC = AuthFlowViewController(
            manifest: manifest,
            returnUrl: returnUrl,
            completion: { [weak self] result in
                guard let self = self else { return }
                Task {
                    await self.completeFlow(result: result)
                }
            }
        )
        self.authFlowViewController = authFlowVC

        navigationController?.pushViewController(authFlowVC, animated: false)
    }

    private func showError(_ error: Error) {
        // TODO: Handle errors. For now, we show an alert with the error message.
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
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
            return FinancialConnectionsLinkedBank(
                sessionId: session.id,
                accountId: bankAccount.id,
                displayName: bankAccount.bankName,
                bankName: bankAccount.bankName,
                last4: bankAccount.last4,
                instantlyVerified: false
            )
        case .unparsable:
            fallthrough
        case .none:
            return nil
        }
    }

    private func createInstantDebitsLinkedBankAndComplete(
        from url: URL
    ) {
        guard let paymentMethod = url.extractLinkBankPaymentMethod() else {
            completion(.failed(error: FCLiteError.linkedBankUnavailable))
            return
        }
        let linkedBank = InstantDebitsLinkedBank(
            paymentMethod: paymentMethod,
            bankName: url.extractValue(forKey: "bank_name")?
                // backend can return "+" instead of a more-common encoding of "%20" for spaces
                .replacingOccurrences(of: "+", with: " "),
            last4: url.extractValue(forKey: "last4"),
            linkMode: nil,
            incentiveEligible: url.extractValue(forKey: "incentive_eligible").flatMap { Bool($0) } ?? false,
            linkAccountSessionId: manifest?.id
        )
        completion(.completed(.instantDebits(linkedBank)))
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension ContainerViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        showDismissConfirmation(presentedBy: presentationController.presentedViewController)
    }

    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Return false to prevent automatic dismissal
        return false
    }

    private func showDismissConfirmation(presentedBy viewController: UIViewController) {
        let alertController = UIAlertController(
            title: "Are you sure you want to exit?",
            message: "You haven't finished linking you bank account and all progress will be lost.",
            preferredStyle: .alert
        )

        // Add cancel option
        alertController.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel
        ))

        // Add confirm option
        alertController.addAction(UIAlertAction(
            title: "Yes, exit",
            style: .default,
            handler: { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.completeFlow(result: .cancelled)
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
