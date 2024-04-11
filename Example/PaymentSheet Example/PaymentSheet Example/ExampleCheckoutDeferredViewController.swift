//
//  ExampleCheckoutDeferredViewController.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 3/31/23.
//
// This is an example of an integration using PaymentSheet where you collect payment details before creating an Intent.

import StripePaymentSheet
import UIKit

// View the backend code here: https://glitch.com/edit/#!/stripe-mobile-payment-sheet-custom-deferred
private let baseUrl = "https://stripe-mobile-payment-sheet-custom-deferred.glitch.me"

class ExampleDeferredCheckoutViewController: UIViewController {
    @IBOutlet weak var buyButton: UIButton!

    @IBOutlet weak var hotDogQuantityLabel: UILabel!
    @IBOutlet weak var saladQuantityLabel: UILabel!
    @IBOutlet weak var hotDogStepper: UIStepper!
    @IBOutlet weak var saladStepper: UIStepper!
    @IBOutlet weak var subtotalLabel: UILabel!
    @IBOutlet weak var salesTaxLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var subscribeSwitch: UISwitch!

    private let backendCheckoutUrl = URL(string: baseUrl + "/checkout")!
    private let confirmIntentUrl = URL(string: baseUrl + "/confirm_intent")!
    private let computeTotalsUrl = URL(string: baseUrl + "/compute_totals")!

    private struct ComputedTotals: Decodable {
        let subtotal: Double
        let tax: Double
        let total: Double
    }

    private var computedTotals: ComputedTotals!

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private var intentConfiguration: PaymentSheet.IntentConfiguration {
        return .init(mode: .payment(amount: Int(computedTotals.total),
                                    currency: "USD",
                                    setupFutureUsage: subscribeSwitch.isOn ? .offSession : nil)
        ) { [weak self] paymentMethod, shouldSavePaymentMethod, intentCreationCallback in
            self?.serverSideConfirmHandler(paymentMethod.stripeId, shouldSavePaymentMethod, intentCreationCallback)
        }
    }

    lazy var paymentSheetConfiguration: PaymentSheet.Configuration = {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = .init(
            merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
            merchantCountryCode: "US"
        )
        configuration.returnURL = "payments-example://stripe-redirect"
        // Set allowsDelayedPaymentMethods to true if your business can handle payment methods that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        return configuration
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false

        hotDogStepper.isEnabled = false
        saladStepper.isEnabled = false
        subscribeSwitch.isEnabled = false

        self.loadCheckout()
    }

    // MARK: - Button handlers

    @objc
    func didTapCheckoutButton() {
        // MARK: Start the checkout process
        let paymentSheet = PaymentSheet(intentConfiguration: intentConfiguration, configuration: paymentSheetConfiguration)
        paymentSheet.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                self.displayAlert("Your order is confirmed!", success: true)
            case .canceled:
                print("Canceled!")
            case .failed(let error):
                print(error)
                self.displayAlert("Payment failed: \n\(error.localizedDescription)", success: false)
            }
        }
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

        fetchTotals { [weak self] in
            guard let self = self else { return }
            self.updateLabels()
            self.buyButton.isEnabled = true
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
            completionHandler: { [weak self] (data, _, _) in
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

                DispatchQueue.main.async {
                    self.computedTotals = ComputedTotals(subtotal: subtotal, tax: tax, total: total)
                    // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
                    STPAPIClient.shared.publishableKey = publishableKey

                    // MARK: Update the configuration.customer details
                    self.paymentSheetConfiguration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                    [self.hotDogStepper, self.saladStepper, self.subscribeSwitch, self.buyButton].forEach { $0?.isEnabled = true }
                    self.updateLabels()
                }
            })

        task.resume()
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
            "customer_id": paymentSheetConfiguration.customer?.id,
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
