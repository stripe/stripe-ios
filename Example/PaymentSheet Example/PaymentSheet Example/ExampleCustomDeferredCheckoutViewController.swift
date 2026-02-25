//
//  ExampleCustomDeferredCheckoutViewController.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/27/23.
//
// This is an example of an integration using PaymentSheet.FlowController where you collect payment details before creating an Intent.

@_spi(STP) import StripePaymentSheet
import UIKit

// View and fork the backend code  here: https://codesandbox.io/p/devbox/dr4lkg
private let baseUrl = "https://stripe-mobile-payment-sheet-custom-deferred.stripedemos.com"

class ExampleCustomDeferredCheckoutViewController: UIViewController {
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

    private var paymentSheetFlowController: PaymentSheet.FlowController!

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
        ) { [weak self] paymentMethod, shouldSavePaymentMethod in
            guard let self = self else {
                throw ExampleError(errorDescription: "View controller was deallocated")
            }
            return try await self.serverSideConfirmHandler(paymentMethod.stripeId, shouldSavePaymentMethod)
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

        Task {
            do {
                try await loadCheckout()
            } catch {
                print("Failed to load checkout: \(error)")
            }
        }
    }

    // MARK: - Button handlers

    @objc
    func didTapPaymentMethodButton() {
        // MARK: Present payment options to the customer
        paymentSheetFlowController.presentPaymentOptions(from: self) {
            self.updateButtons()
        }
    }

    @objc
    func didTapCheckoutButton() {
        // MARK: Confirm payment
        paymentSheetFlowController.confirm(from: self) { paymentResult in
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
        paymentMethodButton.isEnabled = false

        Task {
            do {
                try await fetchTotals()
                updateLabels()

                // Update PaymentSheet with the latest `intentConfig`
                do {
                    try await paymentSheetFlowController.update(intentConfiguration: intentConfig)
                    // Re-enable your "Buy" and "Payment method" buttons
                    updateButtons()
                } catch {
                    print(error)
                    displayAlert("\(error)", success: false)
                    // Retry - production code should use an exponential backoff
                    Task {
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        updateUI()
                    }
                }
            } catch {
                print("Failed to fetch totals: \(error)")
            }
        }
    }

    func updateButtons() {
        paymentMethodButton.isEnabled = true

        // MARK: Update the payment method and buy buttons
        if let paymentOption = paymentSheetFlowController.paymentOption {
            paymentMethodButton.setTitle(paymentOption.label, for: .normal)
            paymentMethodButton.setTitleColor(.label, for: .normal)
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
                                  _ shouldSavePaymentMethod: Bool) async throws -> String {
        // Create and confirm an intent on your server and return the client secret
        return try await confirmIntent(paymentMethodID: paymentMethodID, shouldSavePaymentMethod: shouldSavePaymentMethod)
    }

    // MARK: Networking helpers

    private func fetchTotals() async throws {
        // MARK: Fetch the current amounts from the server
        var request = URLRequest(url: computeTotalsUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let body: [String: Any?] = [
            "hot_dog_count": hotDogStepper.value,
            "salad_count": saladStepper.value,
            "is_subscribing": subscribeSwitch.isOn,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        let totals = try JSONDecoder().decode(ComputedTotals.self, from: data)

        self.computedTotals = totals
    }

    private func loadCheckout() async throws {
        // MARK: Fetch the publishable key, order information, and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let body: [String: Any?] = [
            "hot_dog_count": hotDogStepper.value,
            "salad_count": saladStepper.value,
            "is_subscribing": subscribeSwitch.isOn,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard
            let customerId = json?["customer"] as? String,
            let customerEphemeralKeySecret = json?["ephemeralKey"] as? String,
            let publishableKey = json?["publishableKey"] as? String,
            let subtotal = json?["subtotal"] as? Double,
            let tax = json?["tax"] as? Double,
            let total = json?["total"] as? Double
        else {
            throw ExampleError(errorDescription: "Invalid response from backend")
        }

        self.computedTotals = ComputedTotals(subtotal: subtotal, tax: tax, total: total)
        // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
        STPAPIClient.shared.publishableKey = publishableKey

        // MARK: Create a PaymentSheet.FlowController instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = .init(
            merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
            merchantCountryCode: "US"
        )
        configuration.customer = .init(
            id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
        configuration.returnURL = "payments-example://stripe-redirect"
        // Set allowsDelayedPaymentMethods to true if your business can handle payment methods that complete payment after a delay, like SEPA Debit.
        configuration.allowsDelayedPaymentMethods = true

        let paymentSheetFlowController = try await PaymentSheet.FlowController.create(
            intentConfiguration: self.intentConfig,
            configuration: configuration
        )
        self.paymentSheetFlowController = paymentSheetFlowController
        self.paymentMethodButton.isEnabled = true
        self.hotDogStepper.isEnabled = true
        self.saladStepper.isEnabled = true
        self.subscribeSwitch.isEnabled = true
        self.updateButtons()
        self.updateLabels()
    }

    func confirmIntent(paymentMethodID: String,
                       shouldSavePaymentMethod: Bool) async throws -> String {
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
            "customer_id": paymentSheetFlowController.configuration.customer?.id,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONDecoder().decode([String: String].self, from: data)

        if let clientSecret = json["intentClientSecret"] {
            return clientSecret
        } else {
            throw ExampleError(errorDescription: json["error"] ?? "An unknown error occurred.")
        }
    }

    struct ExampleError: LocalizedError {
       var errorDescription: String?
    }
}
