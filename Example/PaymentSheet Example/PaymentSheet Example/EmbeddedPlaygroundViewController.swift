//
//  EmbeddedPlaygroundViewController.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 9/4/24.
//

import Foundation
@_spi(EmbeddedPaymentElementPrivateBeta) @_spi(STP) @_spi(ExperimentalAllowsRemovalOfLastSavedPaymentMethodAPI) import StripePaymentSheet
import UIKit

class EmbeddedPlaygroundViewController: UIViewController {
    private let appearance: PaymentSheet.Appearance
    private let intentConfig: PaymentSheet.IntentConfiguration
    private let configuration: EmbeddedPaymentElement.Configuration

    private var embeddedPaymentElement: EmbeddedPaymentElement!

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var checkoutButton: UIButton = {
        let checkoutButton = UIButton(type: .system)
        checkoutButton.backgroundColor = appearance.primaryButton.backgroundColor ?? appearance.colors.primary
        checkoutButton.layer.cornerRadius = 5.0
        checkoutButton.clipsToBounds = true
        checkoutButton.setTitle("Checkout", for: .normal)
        checkoutButton.setTitleColor(.white, for: .normal)
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        return checkoutButton
    }()

    init(configuration: EmbeddedPaymentElement.Configuration, intentConfig: PaymentSheet.IntentConfiguration, appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        self.intentConfig = intentConfig
        self.configuration = configuration

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemBackground
            }

            return .systemBackground
        })

        setupLoadingIndicator()
        loadingIndicator.startAnimating()

        Task {
            do {
                try await setupUI()
            } catch {
                presentError(error)
            }

            loadingIndicator.stopAnimating()
        }
    }

    private func setupUI() async throws {
        embeddedPaymentElement = try await EmbeddedPaymentElement.create(intentConfiguration: intentConfig,
                                                                         configuration: configuration)
        embeddedPaymentElement.delegate = self
        embeddedPaymentElement.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(embeddedPaymentElement.view)
        self.view.addSubview(checkoutButton)

        NSLayoutConstraint.activate([
            embeddedPaymentElement.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            embeddedPaymentElement.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            embeddedPaymentElement.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            checkoutButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            checkoutButton.heightAnchor.constraint(equalToConstant: 50),
            checkoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func presentError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

extension EmbeddedPlaygroundViewController: EmbeddedPaymentElementDelegate {
    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
}
