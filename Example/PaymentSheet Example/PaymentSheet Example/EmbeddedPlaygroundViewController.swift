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

    private let configuration: EmbeddedPaymentElement.Configuration

    private let intentConfig: EmbeddedPaymentElement.IntentConfiguration

    private(set) var embeddedPaymentElement: EmbeddedPaymentElement?

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

    private let settingsViewContainer = UIStackView()

    private let paymentOptionView = EmbeddedPaymentOptionView()

    init(
        configuration: EmbeddedPaymentElement.Configuration,
        intentConfig: EmbeddedPaymentElement.IntentConfiguration,
        appearance: PaymentSheet.Appearance
    ) {
        self.appearance = appearance
        self.configuration = configuration
        self.intentConfig = intentConfig

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

        Task { @MainActor in
            do {
                try await setupUI()
            } catch {
                let alert = UIAlertController(
                    title: "Error loading Embedded Payment Element",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }

            loadingIndicator.stopAnimating()
        }
    }

    private func setupUI() async throws {
        let embeddedPaymentElement = try await EmbeddedPaymentElement.create(
            intentConfiguration: intentConfig,
            configuration: configuration
        )
        embeddedPaymentElement.delegate = self
        self.embeddedPaymentElement = embeddedPaymentElement

        // Scroll view contains our content
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // All our content is in a stack view
        let stackView = UIStackView(arrangedSubviews: [settingsViewContainer, embeddedPaymentElement.view, paymentOptionView, checkoutButton])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        stackView.spacing = 16
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        paymentOptionView.configure(with: embeddedPaymentElement.paymentOption, showMandate: !configuration.embeddedViewDisplaysMandateText)
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func setSettingsView(_ settingsView: UIView) {
        settingsViewContainer.arrangedSubviews.forEach { settingsViewContainer.removeArrangedSubview($0) }
        settingsViewContainer.addArrangedSubview(settingsView)
    }
}

// MARK: - EmbeddedPaymentElementDelegate

extension EmbeddedPlaygroundViewController: EmbeddedPaymentElementDelegate {
    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }

    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        paymentOptionView.configure(with: embeddedPaymentElement.paymentOption, showMandate: !configuration.embeddedViewDisplaysMandateText)
    }
}

// MARK: - EmbeddedPaymentOptionView

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

    func configure(with data: EmbeddedPaymentElement.PaymentOptionDisplayData?, showMandate: Bool) {
        titleLabel.isHidden = data == nil
        imageView.image = data?.image
        label.text = data?.label
        mandateTextLabel.attributedText = data?.mandateText
        mandateTextLabel.isHidden = !showMandate
    }
}
