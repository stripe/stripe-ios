//
//  EmbeddedPlaygroundViewController.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 9/4/24.
//

import Foundation
@_spi(EmbeddedPaymentElementPrivateBeta) @_spi(STP) @_spi(ExperimentalAllowsRemovalOfLastSavedPaymentMethodAPI) import StripePaymentSheet
import UIKit

protocol EmbeddedPlaygroundViewControllerDelegate: AnyObject {
    func didComplete(with result: PaymentSheetResult)
}

class EmbeddedPlaygroundViewController: UIViewController {
    private let appearance: PaymentSheet.Appearance
    private let intentConfig: PaymentSheet.IntentConfiguration
    private let configuration: EmbeddedPaymentElement.Configuration
    
    private var embeddedPaymentElement: EmbeddedPaymentElement!
    weak var delegate: EmbeddedPlaygroundViewControllerDelegate?
    
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

    init(configuration: PaymentSheet.Configuration, intentConfig: PaymentSheet.IntentConfiguration, appearance: PaymentSheet.Appearance, delegate: EmbeddedPlaygroundViewControllerDelegate?) {
        self.appearance = appearance
        self.intentConfig = intentConfig
        self.configuration = .init(from: configuration, formSheetAction: .confirm(completion: { result in
            // TODO(porter) Probably pass in formSheetAction from PlaygroundController based on some toggle in the UI
            delegate?.didComplete(with: result)
        }), hidesMandateText: false)
        
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
        embeddedPaymentElement = try await EmbeddedPaymentElement.create(
             intentConfiguration: intentConfig,
             configuration: configuration)
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
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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

extension EmbeddedPaymentElement.Configuration {
    
    /// Initializes an EmbeddedPaymentElement.Configuration from a given PaymentSheet.Configuration.
    ///
    /// - Parameters:
    ///   - paymentSheetConfig: The PaymentSheet.Configuration instance to convert from.
    ///   - formSheetAction: The FormSheetAction specific to EmbeddedPaymentElement.Configuration.
    ///   - hidesMandateText: Determines whether to hide mandate text. Defaults to `false`.
    public init(
        from paymentSheetConfig: PaymentSheet.Configuration,
        formSheetAction: FormSheetAction,
        hidesMandateText: Bool = false
    ) {
        self = .init(formSheetAction: formSheetAction)
        
        self.allowsDelayedPaymentMethods = paymentSheetConfig.allowsDelayedPaymentMethods
        self.allowsPaymentMethodsRequiringShippingAddress = paymentSheetConfig.allowsPaymentMethodsRequiringShippingAddress
        self.apiClient = paymentSheetConfig.apiClient
        self.applePay = paymentSheetConfig.applePay
        self.primaryButtonColor = paymentSheetConfig.primaryButtonColor
        self.primaryButtonLabel = paymentSheetConfig.primaryButtonLabel
        self.style = paymentSheetConfig.style
        self.customer = paymentSheetConfig.customer
        self.merchantDisplayName = paymentSheetConfig.merchantDisplayName
        self.returnURL = paymentSheetConfig.returnURL
        self.defaultBillingDetails = paymentSheetConfig.defaultBillingDetails
        self.savePaymentMethodOptInBehavior = paymentSheetConfig.savePaymentMethodOptInBehavior
        self.appearance = paymentSheetConfig.appearance
        self.shippingDetails = paymentSheetConfig.shippingDetails
        self.preferredNetworks = paymentSheetConfig.preferredNetworks
        self.userOverrideCountry = paymentSheetConfig.userOverrideCountry
        self.billingDetailsCollectionConfiguration = paymentSheetConfig.billingDetailsCollectionConfiguration
        self.removeSavedPaymentMethodMessage = paymentSheetConfig.removeSavedPaymentMethodMessage
        self.externalPaymentMethodConfiguration = paymentSheetConfig.externalPaymentMethodConfiguration
        self.paymentMethodOrder = paymentSheetConfig.paymentMethodOrder
        self.allowsRemovalOfLastSavedPaymentMethod = paymentSheetConfig.allowsRemovalOfLastSavedPaymentMethod
        
        // Handle unique properties for EmbeddedPaymentElement.Configuration
        self.hidesMandateText = hidesMandateText
    }
}
