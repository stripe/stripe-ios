//
//  ExampleOnrampViewController.swift
//  PaymentSheet Example
//
//  Created by Mat Schmid on 6/21/25.
//

@_spi(STP) import StripePayments
@_spi(STP) @_spi(CustomerSessionBetaAccess) import StripePaymentSheet
import UIKit

class ExampleOnrampViewController: UIViewController {
    var paymentSheetFlowController: PaymentSheet.FlowController? {
        didSet {
            startVerification()
        }
    }

    // Hold reference to prevent deallocation
    private var verificationController: LinkVerificationControllerBridge?

    // MARK: - UI Elements

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter Your Contact Info"
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Provide your email address to get started."
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "abc@sample.com"
        textField.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        textField.textColor = .white
        textField.backgroundColor = .clear // Transparent background
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.delegate = self

        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always

        // Style placeholder
        textField.attributedPlaceholder = NSAttributedString(
            string: "abc@sample.com",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        )

        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private lazy var textFieldContainer: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor(red: 24/255, green: 24/255, blue: 24/255, alpha: 1.0)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()

    private lazy var loadingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = UIColor(red: 152/255, green: 134/255, blue: 229/255, alpha: 1.0) // #9886E5
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(red: 152/255, green: 134/255, blue: 229/255, alpha: 1.0) // #9886E5
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    private var continueButtonBottomConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarAppearance()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)

        // Add scroll view and content view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Add UI elements to content view
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(textFieldContainer)

        // Add text field and spinner to container
        textFieldContainer.addSubview(emailTextField)
        textFieldContainer.addSubview(loadingSpinner)

        // Add continue button directly to main view (not scroll view)
        view.addSubview(continueButton)

        setupConstraints()
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        // Continue button bottom constraint (will be animated)
        continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(
            equalTo: safeArea.bottomAnchor,
            constant: 0
        )

        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),

            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Subtitle label constraints
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Text field container constraints
            textFieldContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            textFieldContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textFieldContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textFieldContainer.heightAnchor.constraint(equalToConstant: 56),
            textFieldContainer.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),

            // Email text field constraints within container
            emailTextField.topAnchor.constraint(equalTo: textFieldContainer.topAnchor),
            emailTextField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor),
            emailTextField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -48), // Leave space for spinner

            // Loading spinner constraints within container
            loadingSpinner.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor),
            loadingSpinner.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -16),

            // Continue button constraints
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            continueButtonBottomConstraint,
        ])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupNavigationBar() {
        // Set navigation bar to be transparent with white elements
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true

        // Hide the default back button
        navigationItem.hidesBackButton = true

        // Create custom back button with proper alignment
        setupCustomBackButton()
    }

    private func setupCustomBackButton() {
        // Create a custom back button
        let backButton = UIButton(type: .system)

        // Create a bolder chevron using font configuration
        let chevronConfig = UIImage.SymbolConfiguration(weight: .semibold)
        let chevronImage = UIImage(systemName: "chevron.left", withConfiguration: chevronConfig)

        backButton.setImage(chevronImage, for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        // Set the button size
        backButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -24, bottom: 0, right: 0)

        // Create bar button item with the custom button
        let customBackButton = UIBarButtonItem(customView: backButton)

        // Add negative spacer to align with title (20pt from edge)
        let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpacer.width = -4 // Adjust this value to fine-tune alignment

        navigationItem.leftBarButtonItems = [negativeSpacer, customBackButton]
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func setupNavigationBarAppearance() {
        // Configure navigation bar appearance for iOS 13+
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear

            // Set back button appearance
            appearance.setBackIndicatorImage(UIImage(systemName: "chevron.left"), transitionMaskImage: UIImage(systemName: "chevron.left"))

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
        }

        // Ensure tint color is white
        navigationController?.navigationBar.tintColor = .white
    }

    // MARK: - Actions

    @objc private func continueButtonTapped() {
        resignFirstResponder()
        guard let email = emailTextField.text, !email.isEmpty else {
            // Show validation error
            return
        }

        // Show loading spinner and prepare payment sheet
        showLoadingSpinner()
        preparePaymentSheet()
    }

    private func showLoadingSpinner() {
        // Show and start the spinner
        loadingSpinner.startAnimating()

        // Dim the text field content but keep it visible
        emailTextField.alpha = 0.7
        emailTextField.isUserInteractionEnabled = false

        // Disable the continue button while loading
        continueButton.isEnabled = false
        continueButton.alpha = 0.6
    }

    private func hideLoadingSpinner() {
        // Stop and hide the spinner
        loadingSpinner.stopAnimating()

        // Restore text field appearance and interaction
        emailTextField.alpha = 1.0
        emailTextField.isUserInteractionEnabled = true

        // Re-enable the continue button
        continueButton.isEnabled = true
        continueButton.alpha = 1.0
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let keyboardHeight = keyboardFrame.cgRectValue.height
        continueButtonBottomConstraint.constant = -keyboardHeight

        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        continueButtonBottomConstraint.constant = 0

        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    func preparePaymentSheet() {
        let email = emailTextField.text ?? ""
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        let body = [
            "mode": "payment",
            "merchant_country_code": "US",
            "customer_email": email,
            "amount": "5000",
            "currency": "usd",
            "customer": "new",
            "customer_key_type": "customer_session",
            "customer_session_component_name": "mobile_payment_element",
            "customer_session_payment_method_save": "enabled",
            "customer_session_payment_method_remove": "enabled",
            "customer_session_payment_method_remove_last": "enabled",
            "customer_session_payment_method_redisplay": "enabled",
        ] as [String: Any]
        let json = try! JSONSerialization.data(withJSONObject: body, options: [])

        let backendCheckoutUrl = URL(string: "https://stp-mobile-playground-backend-v7.stripedemos.com/checkout")!
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { (data, _, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
                    let customerId = json["customerId"] as? String,
                    let customerSessionClientSecret = json["customerSessionClientSecret"] as? String,
                    let paymentIntentClientSecret = json["intentClientSecret"] as? String,
                    let publishableKey = json["publishableKey"] as? String
                else {
                    // Handle error
                    return
                }
                // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
                STPAPIClient.shared.publishableKey = publishableKey

                // MARK: Create a PaymentSheet instance
                var configuration = PaymentSheet.Configuration()
                configuration.defaultBillingDetails.email = email
                configuration.merchantDisplayName = "Example, Inc."
                configuration.customer = .init(id: customerId, customerSessionClientSecret: customerSessionClientSecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                configuration.willUseWalletButtonsView = true
                PaymentSheet.FlowController.create(
                    intentConfiguration: .init(mode: .payment(amount: 1000, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil), paymentMethodTypes: ["card", "link", "shop_pay"], confirmHandler: { paymentMethod, _, intentCreationCallback in
                        print(paymentMethod)
                        intentCreationCallback(.success(paymentIntentClientSecret))
                    }),
                    configuration: configuration
                ) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let paymentSheetFlowController):
                        DispatchQueue.main.async {
                            self?.paymentSheetFlowController = paymentSheetFlowController
                        }
                    }
                }
            })
        task.resume()
    }

    private func startVerification() {
        guard let flowController = paymentSheetFlowController else {
            return
        }
        let verificationController = LinkVerificationControllerBridge(flowController: flowController)
        self.verificationController = verificationController
        verificationController.startVerification(from: self) { [weak self] in
            print("Completed.")
            DispatchQueue.main.async {
                self?.hideLoadingSpinner()
                // Clean up the reference
                self?.verificationController = nil
                self?.navigationController?.pushViewController(ExampleKYCIntroViewController(), animated: true)
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension ExampleOnrampViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            continueButtonTapped()
        }
        return true
    }
}
