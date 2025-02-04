/// CozyRestaurantCustomFlow.swift
/// An example SwiftUI view demonstrating a two-step payment flow using PaymentSheet.FlowController.
/// This single file contains both the SwiftUI frontend and minimal example backend communication logic.
/// NOTE: Do not use this code verbatim in production. Be sure to secure your backend and never store
/// secret API keys on the client.
/// ------------------------------------------------------------------------------------

import SwiftUI
import StripePaymentSheet

@available(iOS 15.0, *)
struct CozyRestaurantCustomFlow: View {
    @StateObject private var viewModel = CozyRestaurantFlowModel()
    @State private var isConfirmingPayment = false

    var body: some View {
        // A simple two-step flow:
        // 1) Present or update the payment options.
        // 2) Confirm payment using those chosen options.
        VStack(spacing: 20) {
            Text("The Cozy Restaurant")
                .font(.title)
                .padding()

            if let flowController = viewModel.paymentSheetFlowController {
                // Step 1: Button to show Payment Options (cards, Apple Pay, etc.)
                PaymentSheet.FlowController.PaymentOptionsButton(
                    paymentSheetFlowController: flowController,
                    onSheetDismissed: viewModel.onOptionsCompletion
                ) {
                    // Display the currently selected payment method, or "Select" if none
                    if let paymentOption = flowController.paymentOption {
                        CozyRestaurantPaymentOptionView(
                            paymentOptionDisplayData: paymentOption
                        )
                    } else {
                        Text("Select Payment Method")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()

                // Step 2: Confirm payment with the PaymentSheetFlowController
                Button {
                    isConfirmingPayment = true
                } label: {
                    if isConfirmingPayment {
                        CozyRestaurantLoadingView()
                    } else {
                        // Notice we've configured a custom button label in our PaymentSheet.Configuration
                        // so this text is a placeholder. The actual label will come from PaymentSheet.Configuration.primaryButtonLabel
                        // if you use PaymentSheetUI components. Here we just show a placeholder to match
                        // the "two-step" mental model.
                        Text("Pay and Tip")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                .disabled(flowController.paymentOption == nil || isConfirmingPayment)
                .paymentConfirmationSheet(
                    isConfirming: $isConfirmingPayment,
                    paymentSheetFlowController: flowController,
                    onCompletion: viewModel.onPaymentCompletion
                )
                .padding(.horizontal)
            } else {
                // PaymentSheetFlowController not set up yet
                CozyRestaurantLoadingView()
            }

            // Show the payment result status once done
            if let result = viewModel.paymentResult {
                CozyRestaurantPaymentStatusView(result: result)
            }

            Spacer()
        }
        .onAppear {
            viewModel.preparePaymentSheet()
        }
    }
}

/// A simple ObservableObject that fetches the PaymentIntent details from an example backend
/// and creates a PaymentSheet.FlowController.
class CozyRestaurantFlowModel: ObservableObject {
    // Example endpoint that returns:
    //  - A PaymentIntent client secret
    //  - A Customer ID
    //  - A Customer ephemeral key
    //  - A testmode publishableKey
    //
    // NOTE: Replace this URL with your own backend endpoint.
    private let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!

    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
    @Published var paymentResult: PaymentSheetResult?

    /// Fetch PaymentIntent, create PaymentSheet.FlowController
    func preparePaymentSheet() {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let customerId = json["customer"] as? String,
                let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                let paymentIntentClientSecret = json["paymentIntent"] as? String,
                let publishableKey = json["publishableKey"] as? String,
                error == nil
            else {
                return print("Error fetching backend data or parsing response: \(error?.localizedDescription ?? "No data")")
            }

            // Set the Stripe publishable key so the SDK can make requests
            STPAPIClient.shared.publishableKey = publishableKey

            // Create a PaymentSheet configuration
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "The Cozy Restaurant"
            configuration.returnURL = "payments-example://stripe-redirect"
            configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)

            // For demonstration, let's enable Apple Pay if desired:
            // (Replace with your own Apple Pay merchantId & country code)
            configuration.applePay = .init(
                merchantId: "merchant.com.stripe.test",      // Your Apple merchant identifier
                merchantCountryCode: "US"                    // Your country
            )

            // We only want immediate payment methods (disallow delayed methods)
            configuration.allowsDelayedPaymentMethods = false
            // Style: always dark
            configuration.style = .alwaysDark
            // Use an explicit label on the confirm button
            configuration.primaryButtonLabel = "Pay and Tip"
            // Force customer to explicitly opt in to saving PM
            configuration.savePaymentMethodOptInBehavior = .requiresOptIn

            // Create the FlowController
            PaymentSheet.FlowController.create(
                paymentIntentClientSecret: paymentIntentClientSecret,
                configuration: configuration
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        print("FlowController creation failed: \(error)")
                    case .success(let flowController):
                        self?.paymentSheetFlowController = flowController
                    }
                }
            }
        }
        task.resume()
    }

    /// Called after the Payment Options sheet is dismissed
    func onOptionsCompletion() {
        objectWillChange.send() // Force SwiftUI to refresh if needed
    }

    /// Called after user completes or cancels the payment
    func onPaymentCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {
            self.paymentResult = result

            // If payment succeeded, re-fetch a new PaymentIntent for demonstration
            if case .completed = result {
                self.paymentSheetFlowController = nil
                self.preparePaymentSheet()
            }
        }
    }
}

/// A simple SwiftUI view that shows a loading spinner.
@available(iOS 15.0, *)
struct CozyRestaurantLoadingView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.2)
            .padding()
    }
}

/// A simple SwiftUI view that shows the currently selected payment method option from the FlowController.
struct CozyRestaurantPaymentOptionView: View {
    let paymentOptionDisplayData: PaymentSheet.FlowController.PaymentOptionDisplayData

    var body: some View {
        HStack(spacing: 8) {
            Image(uiImage: paymentOptionDisplayData.image)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 18)

            Text(paymentOptionDisplayData.label)
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.blue)
        .cornerRadius(8)
    }
}

/// A SwiftUI view showing a simple status message for the PaymentSheetResult.
struct CozyRestaurantPaymentStatusView: View {
    let result: PaymentSheetResult

    var body: some View {
        switch result {
        case .completed:
            return Text("Payment complete!").foregroundColor(.green).bold().anyView()
        case .canceled:
            return Text("Payment canceled.").foregroundColor(.gray).anyView()
        case .failed(let error):
            return Text("Payment failed: \(error.localizedDescription)").foregroundColor(.red).anyView()
        }
    }
}

// Helper extension for anyView() usage in SwiftUI conditionals
extension View {
    func anyView() -> AnyView {
        AnyView(self)
    }
}
