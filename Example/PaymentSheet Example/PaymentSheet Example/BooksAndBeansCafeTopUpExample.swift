//
//  BooksAndBeansCafeTopUpExample.swift
//  Example SwiftUI file demonstrating a Stripe PaymentSheet FlowController integration
//  for an in-app wallet top-up scenario.
//
//  NOTE: This sample assumes you have a backend endpoint that returns JSON containing:
//    {
//      "customer": "<CUSTOMER_ID>",
//      "ephemeralKey": "<EPHEMERAL_KEY_SECRET>",
//      "paymentIntent": "<PAYMENT_INTENT_CLIENT_SECRET>",
//      "publishableKey": "<PUBLISHABLE_KEY>"
//    }
//
//  Replace the URL below with your own backend endpoint.
//
//  © 2023 Books & Beans Café. All rights reserved.
//
  
import SwiftUI
import StripePaymentSheet

@available(iOS 15.0, *)
struct BooksAndBeansCafeTopUpExample: View {
    @ObservedObject var model = BooksAndBeansBackendModel()
    @State private var isConfirmingPayment = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let flowController = model.flowController {
                    // A button to present a sheet for choosing or adding a payment method
                    PaymentSheet.FlowController.PaymentOptionsButton(
                        paymentSheetFlowController: flowController,
                        onSheetDismissed: model.onPaymentOptionsDismissed
                    ) {
                        PaymentOptionViewBooks(paymentOptionDisplayData: flowController.paymentOption)
                    }
                    
                    // A button to confirm the payment immediately
                    Button(action: {
                        // Potentially update your PaymentIntent or any amounts before confirming
                        isConfirmingPayment = true
                    }, label: {
                        if isConfirmingPayment {
                            ProgressView("Confirming…")
                        } else {
                            Text("Confirm Top-Up")
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                    })
                    .disabled(flowController.paymentOption == nil || isConfirmingPayment)
                    // Present a confirmation sheet (3DS or other next actions) when isConfirmingPayment = true
                    .paymentConfirmationSheet(
                        isConfirming: $isConfirmingPayment,
                        paymentSheetFlowController: flowController,
                        onCompletion: model.onCompletion
                    )
                    
                } else {
                    // Show a spinner while loading PaymentSheet FlowController
                    ProgressView("Loading…")
                }

                if let result = model.paymentResult {
                    TopUpStatusView(result: result)
                }
            }
            .padding()
            .navigationTitle("Books & Beans Café")
            .onAppear {
                model.preparePaymentSheet()
            }
        }
    }
}

// MARK: - Backend Model

class BooksAndBeansBackendModel: ObservableObject {
    // Replace with your actual backend endpoint for creating top-up PaymentIntents
    private let createTopUpEndpoint = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!

    @Published var flowController: PaymentSheet.FlowController?
    @Published var paymentResult: PaymentSheetResult?

    /// Fetches (or creates) a PaymentIntent on your server for the "top-up",
    /// and retrieves ephemeral key + publishable key for the current customer.
    func preparePaymentSheet() {
        var request = URLRequest(url: createTopUpEndpoint)
        request.httpMethod = "POST"
        // If needed, add JSON body data or headers here for your backend.

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard
                let data = data,
                error == nil,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let customerId = json["customer"] as? String,
                let ephemeralKeySecret = json["ephemeralKey"] as? String,
                let paymentIntentClientSecret = json["paymentIntent"] as? String,
                let publishableKey = json["publishableKey"] as? String
            else {
                // Handle network or decoding errors here
                print("Error: Invalid backend response.")
                return
            }
            // Set your Stripe publishable key so the SDK can make requests on your account’s behalf
            STPAPIClient.shared.publishableKey = publishableKey

            // Build the PaymentSheet.Configuration with our scenario’s requirements
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Books & Beans Café"
            // Always show a dark style
            configuration.style = .alwaysDark

            // Encourage saving payment methods by default, but allow customers to opt out
            configuration.savePaymentMethodOptInBehavior = .requiresOptOut

            // For top-ups, we want to confirm payment right away; do not allow "delayed" methods
            configuration.allowsDelayedPaymentMethods = false

            // We'll only collect email; phone and address are turned off for minimal friction
            configuration.billingDetailsCollectionConfiguration.email = .always
            configuration.billingDetailsCollectionConfiguration.phone = .never
            configuration.billingDetailsCollectionConfiguration.address = .never

            // Set up the customer object so PaymentSheet can retrieve saved payment methods
            configuration.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKeySecret)

            // Return URL for 3D Secure or other web-based flows
            configuration.returnURL = "books-and-beans://stripe-redirect"

            // Create a FlowController for a PaymentIntent
            PaymentSheet.FlowController.create(
                paymentIntentClientSecret: paymentIntentClientSecret,
                configuration: configuration
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        print("FlowController creation failed: \(error)")
                    case .success(let newFlowController):
                        self?.flowController = newFlowController
                    }
                }
            }
        }
        task.resume()
    }

    func onPaymentOptionsDismissed() {
        // Called after PaymentOptionsButton is dismissed.
        objectWillChange.send()
    }

    /// Called when the user has finished confirming (or canceled)
    func onCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {
            self.paymentResult = result

            // If the payment is successful, you might want to refresh the PaymentIntent
            // or create a new one. For this example, let's reset after a successful result:
            if case .completed = result {
                // Clear the FlowController so we can reload a new PaymentIntent
                self.flowController = nil
                self.preparePaymentSheet()
            }
        }
    }
}

// MARK: - Simple UI Components for Demo Purposes

/// A quick view showing the currently selected payment method option (card brand, etc.).
struct PaymentOptionViewBooks: View {
    let paymentOptionDisplayData: PaymentSheet.FlowController.PaymentOptionDisplayData?

    var body: some View {
        HStack {
            if let data = paymentOptionDisplayData {
                Image(uiImage: data.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(data.label)
            } else {
                Text("Select Payment Method")
            }
        }
        .padding(8)
        .foregroundColor(.white)
        .background(Color(.systemGray3))
        .cornerRadius(8)
    }
}

/// Shows a status message once the payment attempt completes
struct TopUpStatusView: View {
    let result: PaymentSheetResult

    var body: some View {
        switch result {
        case .completed:
            return Text("Payment completed!").foregroundColor(.green)
        case .canceled:
            return Text("Payment canceled.").foregroundColor(.orange)
        case .failed(let error):
            return Text("Payment failed: \(error.localizedDescription)").foregroundColor(.red)
        }
    }
}
