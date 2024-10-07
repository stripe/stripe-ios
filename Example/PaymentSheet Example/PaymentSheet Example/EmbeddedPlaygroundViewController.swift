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
    
    private let paymentOptionView = EmbeddedPaymentOptionView()

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
        paymentOptionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(embeddedPaymentElement.view)
        self.view.addSubview(paymentOptionView)
        self.view.addSubview(checkoutButton)

        NSLayoutConstraint.activate([
            embeddedPaymentElement.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            embeddedPaymentElement.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            embeddedPaymentElement.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            paymentOptionView.topAnchor.constraint(equalTo: embeddedPaymentElement.view.bottomAnchor, constant: 25),
            paymentOptionView.widthAnchor.constraint(equalTo: view.widthAnchor),
            paymentOptionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkoutButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            checkoutButton.heightAnchor.constraint(equalToConstant: 50),
            checkoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
        
        paymentOptionView.configure(with: embeddedPaymentElement.paymentOption)
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
    
    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        paymentOptionView.configure(with: embeddedPaymentElement.paymentOption)
    }
}


private class EmbeddedPaymentOptionView: UIView {
        
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Selected payment method"
        return label
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let mandateTextLabel: UILabel = {
        let mandateLabel = UILabel()
        mandateLabel.font = .preferredFont(forTextStyle: .footnote)
        mandateLabel.numberOfLines = 0
        mandateLabel.textColor = .gray
        mandateLabel.translatesAutoresizingMaskIntoConstraints = false
        mandateLabel.textAlignment = .left
        return mandateLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(titleLabel)
        addSubview(imageView)
        addSubview(label)
        addSubview(mandateTextLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            titleLabel.widthAnchor.constraint(equalTo: self.widthAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 25),
            
            imageView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 25),
            imageView.heightAnchor.constraint(equalToConstant: 25),
            
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            label.topAnchor.constraint(equalTo: self.topAnchor),
            label.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            
            mandateTextLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            mandateTextLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            mandateTextLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
        ])
    }
    
    func configure(with data: EmbeddedPaymentElement.PaymentOptionDisplayData?) {
        titleLabel.isHidden = data == nil
        imageView.image = data?.image
        label.text = data?.label
        mandateTextLabel.attributedText = data?.mandateText
    }
}

