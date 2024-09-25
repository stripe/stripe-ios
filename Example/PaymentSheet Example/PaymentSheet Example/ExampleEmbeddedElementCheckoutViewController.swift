//
//  ExampleEmbeddedElementCheckoutViewController.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 9/25/24.
//

// TODO: Not testable
@_spi(STP) @testable import StripePaymentSheet
import UIKit

// View the backend code here: https://glitch.com/edit/#!/stripe-mobile-payment-sheet-custom-deferred
private let baseUrl = "https://stripe-mobile-payment-sheet-custom-deferred.glitch.me"

class ExampleEmbeddedElementCheckoutViewController: UIViewController {
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var paymentMethodButton: UIButton!
    @IBOutlet weak var paymentMethodImage: UIImageView!

    @IBOutlet weak var hotDogQuantityLabel: UILabel!
    @IBOutlet weak var saladQuantityLabel: UILabel!
    @IBOutlet weak var hotDogStepper: UIStepper!
    @IBOutlet weak var saladStepper: UIStepper!
    @IBOutlet weak var subtotalLabel: UILabel!
    @IBOutlet weak var salesTaxLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var subscribeSwitch: UISwitch!

    var embeddedPaymentElement: EmbeddedPaymentElement!

    private let backendCheckoutUrl = URL(string: baseUrl + "/checkout")!
    private let confirmIntentUrl = URL(string: baseUrl + "/confirm_intent")!
    private let computeTotalsUrl = URL(string: baseUrl + "/compute_totals")!

    private struct ComputedTotals: Decodable {
        let subtotal: Double
        let tax: Double
        let total: Double
    }

    private var computedTotals: ComputedTotals!

    private var intentConfig: PaymentSheet.IntentConfiguration {
        return .init(mode: .payment(amount: Int(computedTotals.total),
                                    currency: "USD",
                                    setupFutureUsage: subscribeSwitch.isOn ? .offSession : nil)
        ) { [weak self] paymentMethod, shouldSavePaymentMethod, intentCreationCallback in
            // TODO(yuki): Show client-side confirm, not server-side confirm.
            self?.serverSideConfirmHandler(paymentMethod.stripeId, shouldSavePaymentMethod, intentCreationCallback)
        }
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false

        paymentMethodButton.addTarget(self, action: #selector(didTapPaymentMethodButton), for: .touchUpInside)
        paymentMethodButton.isEnabled = false

        hotDogStepper.isEnabled = false
        saladStepper.isEnabled = false
        subscribeSwitch.isEnabled = false

        self.loadCheckout()
    }

    // MARK: - Button handlers

    @objc
    func didTapPaymentMethodButton() {
        let paymentMethodsViewController = PaymentMethodsViewController(embeddedPaymentElement: embeddedPaymentElement)
        let navController = UINavigationController(rootViewController: paymentMethodsViewController)
        present(navController, animated: true)
    }

    @objc
    func didTapCheckoutButton() {
    }

    @IBAction func hotDogStepperDidChange() {
        updateUI()
    }

    @IBAction func saladStepperDidChange() {
        updateUI()
    }

    @IBAction func subscribeSwitchDidChange() {
        updateUI()
    }

    // MARK: - Helper methods

    private func updateUI() {
        // Disable buy and payment method buttons
        buyButton.isEnabled = false
        paymentMethodButton.isEnabled = false

        fetchTotals { [weak self] in
            guard let self = self else { return }
            self.updateLabels()

            Task {
                // Update PaymentSheet with the latest `intentConfig`
                let updateResult = await self.embeddedPaymentElement.update(intentConfiguration: self.intentConfig)
                Task.detached { @MainActor in
                    switch updateResult {
                    case .canceled:
                        // Do nothing; this happens when a subsequent `update` call cancels this one
                        break
                    case .failed(error: let error):
                        print(error)
// Display error to user in an alert, let them retry
                                            case .succeeded:
                        // e.g. stop showing a progress spinner
                        self.updateButtons()
                    }
                }
            }

//            self.paymentSheetFlowController.update(intentConfiguration: self.intentConfig) { [weak self] error in
//                if let error = error {
//                    print(error)
//                    self?.displayAlert("\(error)", success: false)
//                    // Retry - production code should use an exponential backoff
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
//                        self?.updateUI()
//                    }
//                } else {
//                    // Re-enable your "Buy" and "Payment method" buttons
//                    self?.updateButtons()
//                  }
//            }
        }
    }

    func updateButtons() {
        paymentMethodButton.isEnabled = true

        // MARK: Update the payment method and buy buttons
        if let paymentOption = embeddedPaymentElement.paymentOption {
            paymentMethodButton.setTitle(paymentOption.label, for: .normal)
            paymentMethodButton.setTitleColor(.black, for: .normal)
            paymentMethodImage.image = paymentOption.image
            buyButton.isEnabled = true
        } else {
            paymentMethodButton.setTitle("Select", for: .normal)
            paymentMethodButton.setTitleColor(.systemBlue, for: .normal)
            paymentMethodImage.image = nil
            buyButton.isEnabled = false
        }
    }

    func updateLabels() {
        hotDogQuantityLabel.text = "\(Int(hotDogStepper.value))"
        saladQuantityLabel.text = "\(Int(saladStepper.value))"

        subtotalLabel.text = "\(currencyFormatter.string(from: NSNumber(value: computedTotals.subtotal / 100)) ?? "")"
        salesTaxLabel.text = "\(currencyFormatter.string(from: NSNumber(value: computedTotals.tax / 100)) ?? "")"
        totalLabel.text = "\(currencyFormatter.string(from: NSNumber(value: computedTotals.total / 100)) ?? "")"
    }

    func displayAlert(_ message: String, success: Bool) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            alertController.dismiss(animated: true) {
                if success {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: Server-side confirm handler

    func serverSideConfirmHandler(_ paymentMethodID: String,
                                  _ shouldSavePaymentMethod: Bool,
                                  _ intentCreationCallback: @escaping (Result<String, Error>) -> Void) {
        // Create and confirm an intent on your server and invoke `intentCreationCallback` with the client secret
        confirmIntent(paymentMethodID: paymentMethodID, shouldSavePaymentMethod: shouldSavePaymentMethod) { result in
            switch result {
            case .success(let clientSecret):
                intentCreationCallback(.success(clientSecret))
            case .failure(let error):
                intentCreationCallback(.failure(error))
            }
        }
    }

    // MARK: Networking helpers

    private func fetchTotals(completion: @escaping () -> Void) {
        // MARK: Fetch the current amounts from the server
        var request = URLRequest(url: computeTotalsUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let body: [String: Any?] = [
            "hot_dog_count": hotDogStepper.value,
            "salad_count": saladStepper.value,
            "is_subscribing": subscribeSwitch.isOn,
        ]

        request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])

        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, _, _) in
                guard let data = data,
                      let totals = try? JSONDecoder().decode(ComputedTotals.self, from: data) else {
                          fatalError("Failed to decode compute_totals response")
                        }

                self?.computedTotals = totals
                DispatchQueue.main.async {
                    completion()
                }
            })

        task.resume()
    }

    private func loadCheckout() {
        // MARK: Fetch the publishable key, order information, and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let body: [String: Any?] = [
            "hot_dog_count": hotDogStepper.value,
            "salad_count": saladStepper.value,
            "is_subscribing": subscribeSwitch.isOn,
        ]

        request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])

        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, _, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
                    let customerId = json["customer"] as? String,
                    let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                    let publishableKey = json["publishableKey"] as? String,
                    let subtotal = json["subtotal"] as? Double,
                    let tax = json["tax"] as? Double,
                    let total = json["total"] as? Double,
                    let self = self
                else {
                    // Handle error
                    return
                }

                self.computedTotals = ComputedTotals(subtotal: subtotal, tax: tax, total: total)
                // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
                STPAPIClient.shared.publishableKey = publishableKey

                // MARK: Create a EmbeddedPaymentElement instance
                var configuration = EmbeddedPaymentElement.Configuration(
                    formSheetAction: .confirm(completion: { [weak self] result in
                        self?.handlePaymentResult(result)
                    })
                )
                configuration.merchantDisplayName = "Example, Inc."
                configuration.applePay = .init(
                    merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
                    merchantCountryCode: "US"
                )
                configuration.customer = .init(
                    id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                // Set allowsDelayedPaymentMethods to true if your business can handle payment methods that complete payment after a delay, like SEPA Debit and Sofort.
                configuration.allowsDelayedPaymentMethods = true
                Task {
                    do {
                        let embeddedPaymentElement = try await EmbeddedPaymentElement.create(
                            intentConfiguration: self.intentConfig,
                            configuration: configuration
                        )
                        self.embeddedPaymentElement = embeddedPaymentElement
                        self.paymentMethodButton.isEnabled = true
                        self.hotDogStepper.isEnabled = true
                        self.saladStepper.isEnabled = true
                        self.subscribeSwitch.isEnabled = true
                        self.updateButtons()
                        self.updateLabels()
                    } catch {
                        print(error) // Your integration could show the error to the user and prompt them to retry
                    }
                }
            }
        )
        task.resume()
    }

    func handlePaymentResult(_ result: EmbeddedPaymentElementResult) {
        // ...explained later
    }

    func confirmIntent(paymentMethodID: String,
                       shouldSavePaymentMethod: Bool,
                       completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: confirmIntentUrl)
        request.httpMethod = "POST"

        let body: [String: Any?] = [
            "payment_method_id": paymentMethodID,
            "currency": "USD",
            "hot_dog_count": hotDogStepper.value,
            "salad_count": saladStepper.value,
            "is_subscribing": subscribeSwitch.isOn,
            "should_save_payment_method": shouldSavePaymentMethod,
            "return_url": "payments-example://stripe-redirect",
//            "customer_id": paymentSheetFlowController.configuration.customer?.id,
        ]

        request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { (data, _, error) in
                guard
                    error == nil,
                    let data = data,
                    let json = try? JSONDecoder().decode([String: String].self, from: data)
                else {
                    completion(.failure(error ?? ExampleError(errorDescription: "An unknown error occurred.")))
                    return
                }
                if let clientSecret = json["intentClientSecret"] {
                    completion(.success(clientSecret))
                } else {
                    completion(.failure(error ?? ExampleError(errorDescription: json["error"] ?? "An unknown error occurred.")))
                }
        })

        task.resume()
    }

    struct ExampleError: LocalizedError {
       var errorDescription: String?
    }
}

// MARK: - PaymentMethodsViewController
private class PaymentMethodsViewController: UIViewController {
    let embeddedPaymentElement: EmbeddedPaymentElement
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
       return UIScrollView()
    }()

    init(embeddedPaymentElement: EmbeddedPaymentElement) {
        self.embeddedPaymentElement = embeddedPaymentElement
        super.init(nibName: nil, bundle: nil)
        self.embeddedPaymentElement.presentingViewController = self
        self.embeddedPaymentElement.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        embeddedPaymentElement.view.translatesAutoresizingMaskIntoConstraints = false
        let embeddedPaymentElementView = embeddedPaymentElement.view
        scrollView.addSubview(embeddedPaymentElementView)
        NSLayoutConstraint.activate([
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: embeddedPaymentElementView.topAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: embeddedPaymentElementView.bottomAnchor),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: embeddedPaymentElementView.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: embeddedPaymentElementView.trailingAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: embeddedPaymentElementView.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: embeddedPaymentElementView.trailingAnchor),
        ])

        // Nav bar
        title = "Choose your payment method"
        let closeButton = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeButtonTapped))
        navigationItem.leftBarButtonItem = closeButton
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

extension PaymentMethodsViewController: EmbeddedPaymentElementDelegate {
  func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {
    // Lay out the scroll view that contains the Embedded Payment Element view
    scrollView.setNeedsLayout()
    scrollView.layoutIfNeeded()
  }
}
