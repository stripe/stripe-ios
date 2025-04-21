//
//  EmbeddedPlaygroundViewController.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 9/4/24.
//

import Foundation
@_spi(EmbeddedPaymentElementPrivateBeta) @_spi(STP) @_spi(ExperimentalAllowsRemovalOfLastSavedPaymentMethodAPI) import StripePaymentSheet
import UIKit
import Combine
import SwiftUI

class EmbeddedPlaygroundViewController: UIViewController {
    private var hostingController: UIHostingController<AnyView>?
    private var cancellables = Set<AnyCancellable>()
    private weak var playgroundController: PlaygroundController?
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                view.bringSubviewToFront(loadingIndicator)
                loadingIndicator.startAnimating()
                view.isUserInteractionEnabled = false
            } else {
                loadingIndicator.stopAnimating()
                view.isUserInteractionEnabled = true
            }
        }
    }
    private lazy var appearance: PaymentSheet.Appearance = {
        return configuration.appearance
    }()

    private let configuration: EmbeddedPaymentElement.Configuration

    private let intentConfig: EmbeddedPaymentElement.IntentConfiguration

    private(set) var embeddedPaymentElement: EmbeddedPaymentElement?

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

#if DEBUG
    private lazy var testHeightChangeButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = appearance.primaryButton.backgroundColor ?? appearance.colors.primary
        button.layer.cornerRadius = 5.0
        button.clipsToBounds = true
        button.setTitle("Test Height Change", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = true
        button.addTarget(self, action: #selector(testHeightChange), for: .touchUpInside)
        return button
    }()
#endif

    private lazy var checkoutButton: UIButton = {
        let checkoutButton = UIButton(type: .system)
        checkoutButton.backgroundColor = appearance.primaryButton.backgroundColor ?? appearance.colors.primary
        checkoutButton.layer.cornerRadius = 5.0
        checkoutButton.clipsToBounds = true
        checkoutButton.setTitle("Checkout", for: .normal)
        checkoutButton.setTitleColor(.white, for: .normal)
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        checkoutButton.isEnabled = embeddedPaymentElement?.paymentOption != nil
        checkoutButton.addTarget(self, action: #selector(pay), for: .touchUpInside)
        return checkoutButton
    }()
    
    private lazy var clearPaymentOptionButton: UIButton = {
        let resetButton = UIButton(type: .system)
        resetButton.backgroundColor = .systemGray5
        resetButton.layer.cornerRadius = 5.0
        resetButton.clipsToBounds = true
        resetButton.setTitle("Clear payment option", for: .normal)
        resetButton.setTitleColor(.label, for: .normal)
        resetButton.accessibilityIdentifier = "Clear payment option"
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(clearSelection), for: .touchUpInside)
        return resetButton
    }()

    private let settingsViewContainer = UIStackView()

    private let paymentOptionView = EmbeddedPaymentOptionView()

    init(
        configuration: EmbeddedPaymentElement.Configuration,
        intentConfig: EmbeddedPaymentElement.IntentConfiguration,
        playgroundController: PlaygroundController
    ) {
        self.configuration = configuration
        self.intentConfig = intentConfig
        self.playgroundController = playgroundController
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observePlaygroundController()
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
        embeddedPaymentElement.presentingViewController = self
        self.embeddedPaymentElement = embeddedPaymentElement
        self.embeddedPaymentElement?.presentingViewController = self
        
        // Scroll view contains our content
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // All our content is in a stack view
        let stackView = UIStackView(arrangedSubviews: [
            settingsViewContainer,
            embeddedPaymentElement.view,
            paymentOptionView,
            checkoutButton,
            clearPaymentOptionButton
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .init(top: 0, left: 16, bottom: 16, right: 16)
        stackView.spacing = 16
        scrollView.addSubview(stackView)

#if DEBUG
        stackView.addArrangedSubview(testHeightChangeButton)
#endif

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
            checkoutButton.heightAnchor.constraint(equalToConstant: 45),
            clearPaymentOptionButton.heightAnchor.constraint(equalToConstant: 45)
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

    func setSettingsView<SettingsView: View>(_ settingsView: @escaping () -> SettingsView) {
        guard let playgroundController else { return }
        // Remove existing hosting controller if any
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        // Create new hosting controller
        let rootView = settingsView().environmentObject(playgroundController)
        hostingController = UIHostingController(rootView: AnyView(rootView))

        guard let hostingController = hostingController else { return }

        // Add as child view controller
        addChild(hostingController)
        settingsViewContainer.addArrangedSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    private func observePlaygroundController() {
        guard let playgroundController else { return }
        playgroundController.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, let playgroundController = self.playgroundController else { return }
                    self.hostingController?.rootView = AnyView(
                        EmbeddedSettingsView().environmentObject(playgroundController)
                    )
                }
            }
            .store(in: &cancellables)
    }

    @objc func pay() {
        Task { @MainActor in
            guard let embeddedPaymentElement else { return }
            self.isLoading = true
            let result = await embeddedPaymentElement.confirm()
            self.isLoading = false
            
            switch result {
            case .completed, .failed:
                playgroundController?.lastPaymentResult = result
                self.dismiss(animated: true)
            case .canceled:
                break
            }
        }
    }
#if DEBUG
    @objc func testHeightChange() {
        self.embeddedPaymentElement?.testHeightChange()
    }
#endif

    @objc func clearSelection() {
        embeddedPaymentElement?.clearPaymentOption()
    }

}

// MARK: - EmbeddedPaymentElementDelegate

extension EmbeddedPlaygroundViewController: EmbeddedPaymentElementDelegate {
    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }

    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        checkoutButton.isEnabled = embeddedPaymentElement.paymentOption != nil
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
        label.accessibilityIdentifier = "Payment method"
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

    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
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
        let horizontalStackView = UIStackView(arrangedSubviews: [imageView, label])
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 12
        horizontalStackView.alignment = .center

        verticalStackView.addArrangedSubview(titleLabel)
        verticalStackView.addArrangedSubview(horizontalStackView)
        verticalStackView.addArrangedSubview(mandateTextLabel)

        addSubview(verticalStackView)

        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            verticalStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            verticalStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            verticalStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15),
            imageView.widthAnchor.constraint(equalToConstant: 25),
            imageView.heightAnchor.constraint(equalToConstant: 25),
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
