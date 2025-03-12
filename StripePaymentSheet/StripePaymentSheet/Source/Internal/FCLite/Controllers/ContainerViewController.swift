//
//  ContainerViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-12.
//

import UIKit

class ContainerViewController: UIViewController {
    private let clientSecret: String
    private let returnUrl: URL
    private let apiClient: FCLiteAPIClient
    private let completion: ((FinancialConnectionsLite.FlowResult) -> Void)

    private let spinner = UIActivityIndicatorView(style: .large)

    private var authFlowViewController: AuthFlowViewController?

    init(
        clientSecret: String,
        returnUrl: URL,
        apiClient: FCLiteAPIClient,
        completion: @escaping ((FinancialConnectionsLite.FlowResult) -> Void)
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
            await fetchHostedUrl()
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

    private func fetchHostedUrl() async {
        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }

        do {
            let synchronize = try await apiClient.synchronize(
                clientSecret: clientSecret,
                returnUrl: returnUrl
            )
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
        if case .failure(let error) = result {
            completion(.failure(error))
            return
        }

        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: false)
            self.spinner.startAnimating()
        }

        do {
            let session = try await apiClient.fetchSession(clientSecret: clientSecret)
            if session.accounts.data.isEmpty {
                completion(.canceled)
            } else {
                completion(.success(session))
            }

            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        } catch {
            completion(.failure(error))

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
                    await self.completeFlow(result: .canceled)
                }
            }
        ))

        viewController.present(alertController, animated: true)
    }
}
