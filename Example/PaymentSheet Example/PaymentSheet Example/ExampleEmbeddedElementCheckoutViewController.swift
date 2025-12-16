//
//  ExampleEmbeddedElementCheckoutViewController.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 9/25/24.
//

import StripePaymentSheet
import UIKit

// View and fork the backend code  here: https://codesandbox.io/p/devbox/dr4lkg
private let baseUrl = "https://stripe-mobile-payment-sheet-custom-deferred.stripedemos.com"

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
    @IBOutlet weak var mandateTextView: UITextView!

    var embeddedPaymentElement: EmbeddedPaymentElement!
    private var paymentMethodsViewController: EmbeddedPaymentElementWrapperViewController?

    private let backendCheckoutUrl = URL(string: baseUrl + "/checkout")!
    private let confirmIntentUrl = URL(string: baseUrl + "/confirm_intent")!
    private let computeTotalsUrl = URL(string: baseUrl + "/compute_totals")!

    private struct ComputedTotals: Decodable {
        let subtotal: Double
        let tax: Double
        let total: Double
    }

    private var computedTotals: ComputedTotals!

    // MARK: - Create an IntentConfiguration
    private var intentConfig: PaymentSheet.IntentConfiguration {
        return .init(mode: .payment(amount: Int(computedTotals.total),
                                    currency: "USD",
                                    setupFutureUsage: subscribeSwitch.isOn ? .offSession : nil)
        ) { [weak self] paymentMethod, shouldSavePaymentMethod in
            // Create and confirm an intent on your server and invoke `intentCreationCallback` with the client secret or an error.
            // TODO(https://jira.corp.stripe.com/browse/MOBILESDK-2577) Show client-side confirm, not server-side confirm.
            guard let self else {
                throw ExampleError()
            }
            return try await self.createIntent(paymentMethodID: paymentMethod.stripeId, shouldSavePaymentMethod: shouldSavePaymentMethod)
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
        self.view.backgroundColor = .systemBackground
        Task {
            await self.loadCheckout()
        }
    }

    @objc
    func didTapPaymentMethodButton() {
        let paymentMethodsViewController = EmbeddedPaymentElementWrapperViewController(embeddedPaymentElement: embeddedPaymentElement, needsDismissal: { [weak self] in
            self?.embeddedPaymentElement.presentingViewController = self
            self?.dismiss(animated: true)
            self?.updateLabels()
            self?.updateButtons()
        })
        self.paymentMethodsViewController = paymentMethodsViewController
        let navController = UINavigationController(rootViewController: paymentMethodsViewController)
        present(navController, animated: true)
    }

    @objc
    func didTapCheckoutButton() {
        Task {
            // MARK: - Confirm the payment
            // Disable interaction so that customers can't e.g. update their cart or tap the buy button again while we complete payment
            view.isUserInteractionEnabled = false
            let result = await embeddedPaymentElement.confirm()
            handlePaymentResult(result)
            view.isUserInteractionEnabled = true
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

    private func updateUI() {
        // Disable buy and payment method buttons while we're updating
        buyButton.isEnabled = false
        paymentMethodButton.isEnabled = false

        // Update the payment details
        fetchTotals { [weak self] in
            guard let self = self else { return }
            self.updateLabels()

            Task {
                // MARK: - Update payment details
                // Update Embedded Payment Element with the latest `intentConfig`
                let updateResult = await self.embeddedPaymentElement.update(intentConfiguration: self.intentConfig)
                Task.detached { @MainActor [weak self] in
                    guard let self else { return }
                    paymentMethodButton.isEnabled = true
                    switch updateResult {
                    case .canceled:
                        // Do nothing; this happens when a subsequent `update` call cancels this one
                        break
                    case .failed(error: let error):
                        // Display error to user in an alert, let them retry
                        let alertController = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                            self.updateUI()
                        })
                        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
                        present(alertController, animated: true, completion: nil)
                    case .succeeded:
                        self.updateButtons()
                        self.updateLabels()
                    }
                }
            }
        }
    }

    func updateButtons() {
        // MARK: Update the payment method and buy buttons using `paymentOption`
        if let paymentOption = embeddedPaymentElement.paymentOption {
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
        // MARK: Display mandate text ourselves, since we set `embeddedViewDisplaysMandateText` to false
        mandateTextView.attributedText = embeddedPaymentElement.paymentOption?.mandateText
    }

    func displayAlert(_ message: String, shouldDismiss: Bool) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            alertController.dismiss(animated: true) {
                if shouldDismiss {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }

    private func fetchTotals(completion: @escaping () -> Void) {
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

    private func loadCheckout() async {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let body: [String: Any?] = [
            "hot_dog_count": hotDogStepper.value,
            "salad_count": saladStepper.value,
            "is_subscribing": subscribeSwitch.isOn,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let customerId = json["customer"] as? String,
                let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                let publishableKey = json["publishableKey"] as? String,
                let subtotal = json["subtotal"] as? Double,
                let tax = json["tax"] as? Double,
                let total = json["total"] as? Double
            else {
                self.displayAlert("Bad network response", shouldDismiss: true)
                return
            }
            self.computedTotals = ComputedTotals(subtotal: subtotal, tax: tax, total: total)

            // MARK: - Create a EmbeddedPaymentElement instance
            var configuration = EmbeddedPaymentElement.Configuration()
            configuration.formSheetAction = .continue
            // This example displays the buy button in a screen that is separate from screen that displays the embedded view, so we disable the mandate text in the embedded view and show it near our buy button.
            configuration.embeddedViewDisplaysMandateText = false
            configuration.merchantDisplayName = "Example, Inc."
            // Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
            configuration.apiClient.publishableKey = publishableKey
            configuration.applePay = .init(
                merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
                merchantCountryCode: "US"
            )
            configuration.customer = .init(
                id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
            configuration.returnURL = "payments-example://stripe-redirect"
            // Set allowsDelayedPaymentMethods to true if your business can handle payment methods that complete payment after a delay, like SEPA Debit.
            configuration.allowsDelayedPaymentMethods = true
            configuration.appearance.embeddedPaymentElement.row.flat.bottomSeparatorEnabled = false
            configuration.appearance.embeddedPaymentElement.row.flat.topSeparatorEnabled = false
            let embeddedPaymentElement = try await EmbeddedPaymentElement.create(
                intentConfiguration: self.intentConfig,
                configuration: configuration
            )
            embeddedPaymentElement.presentingViewController = self
            self.embeddedPaymentElement = embeddedPaymentElement
            self.paymentMethodButton.isEnabled = true
            self.hotDogStepper.isEnabled = true
            self.saladStepper.isEnabled = true
            self.subscribeSwitch.isEnabled = true
            self.updateButtons()
            self.updateLabels()
        } catch {
            // Handle error here
            self.displayAlert("Error: \(error)", shouldDismiss: true)
        }
    }

    // MARK: - Handle payment result
    func handlePaymentResult(_ result: EmbeddedPaymentElementResult) {
        switch result {
        case .completed:
            displayAlert("Your order is confirmed!", shouldDismiss: true)
        case .canceled:
            print("Canceled!")
        case .failed(let error):
            print(error)
            displayAlert("Payment failed: \n\(error)", shouldDismiss: false)
        }
    }

    func createIntent(paymentMethodID: String, shouldSavePaymentMethod: Bool) async throws -> String {
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
            "customer_id": embeddedPaymentElement.configuration.customer?.id,
        ]

        request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONDecoder().decode([String: String].self, from: data)
        guard
            let clientSecret = json["intentClientSecret"]
        else {
            throw ExampleError(errorDescription: json["error"] ?? "An unknown error occurred.")
        }
        return clientSecret
    }

    struct ExampleError: LocalizedError {
       var errorDescription: String?
    }
}
