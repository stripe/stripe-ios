//Below is a single-file SwiftUI example demonstrating a “deferred” PaymentSheet integration for a hypothetical travel booking service, “Wanderlust Travel Agency.” This example uses Stripe’s PaymentSheet.IntentConfiguration with deferred confirmation, allows delayed payment methods, supports Apple Pay, uses style .automatic, and requires explicit opt-in to save a payment method.
//
//In a real app, you would replace the placeholder backend URL ("https://your-backend.example.com/create_ephemeral_key") with your own server endpoint(s) that return the necessary information (publishable key, ephemeral key, etc.). The code also demonstrates how to “defer” the final charge by returning COMPLETE_WITHOUT_CONFIRMING_INTENT in the confirmHandler:

//  WanderlustDeferredPaymentExample.swift
//  Example of a single-file SwiftUI PaymentSheet with deferred confirmation.
//  Allows delayed payment methods, Apple Pay, and explicitly requires users
//  to opt in before saving payment details.
//
//  Important: Replace the placeholders with your actual backend URLs and publishable key.
//  Demo only — not production-ready.

import SwiftUI
@_spi(STP) @_spi(PaymentSheetSkipConfirmation) import StripePaymentSheet
@_spi(STP) import StripePayments
@available(iOS 15.0, *)
struct WanderlustDeferredPaymentExample: View {
    @ObservedObject var model = WanderlustDeferredPaymentModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Wanderlust Travel Booking")
                .font(.title2)
                .padding(.top, 40)

            if let paymentSheet = model.paymentSheet {
                // Display a ready-to-use Payment button
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: model.onPaymentCompletion
                ) {
                    Text("Reserve My Trip")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }.padding()
            } else {
                // Loading spinner / or “Loading…” UI
                ProgressView("Loading payment sheet…")
                    .padding()
            }

            // Display the last payment result (if any)
            if let result = model.paymentResult {
                switch result {
                case .completed:
                    Text("Payment success! Your trip is reserved.")
                        .foregroundColor(.green)
                case .canceled:
                    Text("Payment canceled or incomplete.")
                        .foregroundColor(.orange)
                case .failed(let error):
                    Text("Payment failed: \(error.localizedDescription)")
                        .foregroundColor(.red)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            model.preparePaymentSheet()
        }
    }
}

class WanderlustDeferredPaymentModel: ObservableObject {
    // Replace this with your actual backend endpoint for ephemeral keys and client setup.
    private let backendURL = URL(string: "https://stp-mobile-playground-backend-v7.stripedemos.com/checkout")!

    // PaymentSheet instance and result
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    // Called onAppear in the view
    func preparePaymentSheet() {
        // 1. Fetch ephemeral key, publishable key, etc. from your server
        //    In this example, we assume the server returns a JSON:
        //    { "publishableKey": "...", "customerId": "...", "ephemeralKey": "..." }
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let publishableKey = json["publishableKey"] as? String,
                let customerId = json["customerId"] as? String,
                let ephemeralKeySecret = json["customerEphemeralKeySecret"] as? String
            else {
                DispatchQueue.main.async {
                    self.paymentResult = .failed(error: NSError(domain: "BackendError",
                                                                code: 0,
                                                                userInfo: [NSLocalizedDescriptionKey: "Failed to load backend data"]))
                }
                return
            }

            // 2. Set the Stripe publishable key so the SDK can make calls on your account’s behalf
            STPAPIClient.shared.publishableKey = publishableKey

            // 3. Configure PaymentSheet with your desired settings
            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "Wanderlust Travel Agency"
            config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKeySecret)
            config.applePay = .init( merchantId: "merchant.com.stripe.umbrella.test",
                                     merchantCountryCode: "US" )
            // We want to allow delayed payment methods and require the user to manually opt in to saving
            config.allowsDelayedPaymentMethods = true
            config.savePaymentMethodOptInBehavior = .requiresOptIn
            config.style = .automatic

            // 4. Create an IntentConfiguration to use “deferred” confirmation
            //    For example, we're collecting a $99.99 trip reservation
            let intentConfig = PaymentSheet.IntentConfiguration(
                mode: .payment(amount: 9999,  // In cents, e.g. $99.99
                               currency: "USD"),
                confirmHandler: { paymentMethod, shouldSavePaymentMethod, completion in
                    // This is called AFTER the user picks a payment method and taps “Pay.”

                    // For demonstration, we return .success(.COMPLETE_WITHOUT_CONFIRMING_INTENT)
                    // to indicate “We are deferring final capture until the trip is finalized.”
                    // You could also call your backend to attach the paymentMethod to a PaymentIntent
                    // but not confirm it yet, or to do partial holds.
                    completion(.success(PaymentSheet.IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT))
                }
            )

            // 5. On the main thread, create the PaymentSheet using the deferred intent approach
            DispatchQueue.main.async {
                self.paymentSheet = PaymentSheet(intentConfiguration: intentConfig, configuration: config)
            }
        }
        task.resume()
    }

    // Called after the PaymentSheet completes
    func onPaymentCompletion(_ result: PaymentSheetResult) {
        DispatchQueue.main.async {
            // Store the result so the UI can display it
            self.paymentResult = result

            if case .completed = result {
                // If you intended to finalize the PaymentIntent, you might create a new one
                // for the next booking, or refresh your PaymentSheet state. This example:
                self.paymentSheet = nil
            }
        }
    }
}

//--------------------------------------------------------------------------------
//
//Explanation of Key Points:
//
//• PaymentSheet.IntentConfiguration: We pass a confirmHandler so that when the user taps “Pay,” PaymentSheet calls us with the chosen payment method. Here, we simply return COMPLETE_WITHOUT_CONFIRMING_INTENT to indicate that our backend will finalize (capture) the payment at a later time. If you do need to attach or partially confirm this PaymentIntent on your server, you can do so in confirmHandler and then call completion(.success("<new or final client secret>")).
//
//• config.allowsDelayedPaymentMethods = true: Lets your travelers select payment methods that can require extra time or asynchronous steps (e.g., certain bank debits).
//
//• config.savePaymentMethodOptInBehavior = .requiresOptIn: Explicitly requires the user to check a box to save their payment information for future travel bookings.
//
//• config.style = .automatic: Instructs PaymentSheet to match the device’s light/dark appearance.
//
//• config.applePay: Configures Apple Pay. Remember to replace merchantId = "merchant.com.yourApp" with your real Apple Pay Merchant ID.
//
//• COMPLETE_WITHOUT_CONFIRMING_INTENT: Stripe’s way of telling the PaymentSheet that the payment flow is intentionally deferred (i.e., the PaymentIntent is not confirmed at this time).
//
//This single-file example is intentionally minimal. In an actual production app, your backend server endpoints would securely create and manage PaymentIntents, ephemeral keys, and so on.
