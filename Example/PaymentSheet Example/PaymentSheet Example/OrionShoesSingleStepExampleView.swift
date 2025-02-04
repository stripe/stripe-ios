// OrionShoesSingleStepExample.swift
//
// This is a complete SwiftUI example demonstrating a single-step checkout flow
// with Stripe's PaymentSheet for a basic shoe retailer, "Orion Shoes", that
// wants to accept credit cards and Apple Pay. It uses:
//   • style = .automatic
//   • applePay with merchantCountryCode = "US"
//   • allowsDelayedPaymentMethods = false
//   • savePaymentMethodOptInBehavior = .automatic
//
// IMPORTANT: In your real app, replace the placeholder backend URL with your own
// server endpoint, and ensure you use your real Apple Pay merchant ID.

import SwiftUI
import StripePaymentSheet

@available(iOS 15.0, *)
struct OrionShoesSingleStepExampleView: View {
    @ObservedObject private var model = OrionShoesBackendModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Orion Shoes!")
                .font(.headline)
                .padding(.top, 40)

            // If we have a configured PaymentSheet, show the PaymentButton.
            if let paymentSheet = model.paymentSheet {
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: model.onCompletion
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart")
                        Text("Buy Shoes")
                    }
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.indigo)
                    .cornerRadius(8)
                }
            } else {
                // If not ready yet, show a loading spinner
                ProgressView("Loading checkout...")
                    .progressViewStyle(CircularProgressViewStyle())
            }

            // Show the most recent payment result, if any
            if let paymentResult = model.paymentResult {
                ExamplePaymentStatusView(result: paymentResult)
            }
        }
        .padding()
        .onAppear {
            // Prepare the PaymentSheet when this view appears
            model.preparePaymentSheet()
        }
    }
}

// MARK: - Backend Model

class OrionShoesBackendModel: ObservableObject {
    // Example backend endpoint - replace with your own server
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!

    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    func preparePaymentSheet() {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        // Fetch PaymentIntent and Customer info from your backend
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, _, error) in
            guard
                let self = self,
                let data = data,
                error == nil,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let customerId = json["customer"] as? String,
                let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                let paymentIntentClientSecret = json["paymentIntent"] as? String,
                let publishableKey = json["publishableKey"] as? String
            else {
                // Handle error in production
                return
            }

            // Set your Stripe publishable key so the SDK can make requests on behalf of your account
            STPAPIClient.shared.publishableKey = publishableKey

            // Configure the PaymentSheet
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Orion Shoes"
            configuration.style = .automatic
            configuration.applePay = .init(
                merchantId: "merchant.com.stripe.umbrella.test",  // Replace with your own Apple Pay merchant ID
                merchantCountryCode: "US"
            )
            configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
            configuration.returnURL = "payments-example://stripe-redirect"
            configuration.allowsDelayedPaymentMethods = false
            configuration.savePaymentMethodOptInBehavior = .automatic

            // Create the PaymentSheet for a one-step payment
            DispatchQueue.main.async {
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: paymentIntentClientSecret,
                    configuration: configuration
                )
            }
        }

        task.resume()
    }

    // Handle the user completing or cancelling the PaymentSheet
    func onCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {
            self.paymentResult = result
            // If the payment completed successfully, the PaymentIntent cannot be reused,
            // so prepare a fresh PaymentSheet for a new purchase in this demo.
            if case .completed = result {
                self.paymentSheet = nil
                self.preparePaymentSheet()
            }
        }
    }
}
