//
//  ExampleSwiftUIEmbeddedPaymentElement.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/4/25.
//
// This is an example integration using Embedded Payment Element in SwiftUI

import StripePaymentSheet
import SwiftUI

// MARK: - BackendViewModel
class BackendViewModel: ObservableObject {
    struct BackendResponse {
        let publishableKey: String
        let customerID: String
        let ephemeralKey: String
    }

    private let baseUrl = "https://stripe-mobile-payment-sheet-custom-deferred.stripedemos.com"
    private lazy var checkoutUrl = URL(string: baseUrl + "/checkout")!
    private lazy var confirmIntentUrl = URL(string: baseUrl + "/confirm_intent")!
    private lazy var computeTotalsUrl = URL(string: baseUrl + "/compute_totals")!

    /// Store the “current total” (in cents) that we last fetched from the backend
    @Published private(set) var currentTotal: Int = 0
    private var response: BackendResponse?

    // MARK: Step 1) Load ephemeral key & publishable key from /checkout
    @MainActor
    func loadCheckout() async throws -> BackendResponse {
        var request = URLRequest(url: checkoutUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let body: [String: Any] = [
            "hot_dog_count": 5,
            "salad_count": 0,
            "is_subscribing": false,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        guard
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let pk = json["publishableKey"] as? String,
            let cid = json["customer"] as? String,
            let ekey = json["ephemeralKey"] as? String,
            let total = json["total"] as? Int
        else {
            throw URLError(.badServerResponse)
        }

        self.currentTotal = total

        // Set the publishable key on the Stripe SDK
        STPAPIClient.shared.publishableKey = pk

        let response = BackendResponse(publishableKey: pk,
                               customerID: cid,
                               ephemeralKey: ekey)
        self.response = response
        return response
    }

    // MARK: Step 2) Create an IntentConfiguration for the current total and subscription status
    func makeIntentConfiguration(
        isSubscribing: Bool
    ) -> PaymentSheet.IntentConfiguration {
        let amount = currentTotal
        let usage: PaymentSheet.IntentConfiguration.SetupFutureUsage? = isSubscribing ? .offSession : nil

        // When embedded payment element calls back, we confirm on the server with /confirm_intent
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: amount,
                currency: "USD",
                setupFutureUsage: usage
            )
        ) { [weak self] paymentMethod, shouldSavePaymentMethod, intentCreationCallback in
            guard let self = self else { return }
            Task {
                do {
                    let clientSecret = try await self.confirmIntent(
                        paymentMethodID: paymentMethod.stripeId,
                        shouldSavePaymentMethod: shouldSavePaymentMethod,
                        isSubscribing: isSubscribing
                    )
                    intentCreationCallback(.success(clientSecret))
                } catch {
                    intentCreationCallback(.failure(error))
                }
            }
        }
        return intentConfig
    }

    // MARK: Step 3) Confirm on the server side
    private func confirmIntent(
        paymentMethodID: String,
        shouldSavePaymentMethod: Bool,
        isSubscribing: Bool
    ) async throws -> String {
        var request = URLRequest(url: confirmIntentUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let body: [String: Any?] = [
            "payment_method_id": paymentMethodID,
            "currency": "USD",
            "hot_dog_count": 5,
            "salad_count": 0,
            "is_subscribing": isSubscribing,
            "should_save_payment_method": shouldSavePaymentMethod,
            "return_url": "payments-example://stripe-redirect",
            "customer_id": self.response?.customerID,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONDecoder().decode([String: String].self, from: data)

        if let clientSecret = json["intentClientSecret"] {
            return clientSecret
        } else if let error = json["error"] {
            throw ExampleError(errorDescription: error)
        } else {
            throw ExampleError(errorDescription: "Unknown error from server.")
        }
    }

    // MARK: Step 4) If the user changes subscription, we fetch updated totals from /compute_totals
    @MainActor
    func fetchUpdatedTotal(isSubscribing: Bool) async throws {
        var request = URLRequest(url: computeTotalsUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let body: [String: Any] = [
            "hot_dog_count": 5,
            "salad_count": 0,
            "is_subscribing": isSubscribing,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        guard
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let total = json["total"] as? Int
        else {
            throw URLError(.badServerResponse)
        }

        self.currentTotal = total
    }

    struct ExampleError: LocalizedError {
        var errorDescription: String?
    }
}

// MARK: - MyEmbeddedCheckoutView
@available(iOS 15.0, *)
struct MyEmbeddedCheckoutView: View {
    @StateObject var embeddedViewModel = EmbeddedPaymentElementViewModel()
    @StateObject var backendViewModel = BackendViewModel()
    @State var confirmationResult: EmbeddedPaymentElementResult?
    @State var isConfirming = false
    @State private var isSubscribing: Bool = false
    @State private var loadFailed = false

    @Environment(\.dismiss) private var dismiss

    // MARK: Body
    var body: some View {
        ScrollView {
            if embeddedViewModel.isLoaded {
                // Embedded Payment Element
                EmbeddedPaymentElementView(viewModel: embeddedViewModel)

                // Display the selected payment option
                // A real integration probably wouldn't show the selected payment option on the same screen as the embedded payment element. We display it as an example.
                if let paymentOption = embeddedViewModel.paymentOption {
                    HStack {
                        Image(uiImage: paymentOption.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 30)
                        Text(paymentOption.label)
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Subscribe switch
                Toggle("Subscribe for 5% discount", isOn: $isSubscribing)
                    .padding()
                    .onChange(of: isSubscribing) { newValue in
                        Task {
                            await handleSubscriptionToggle(newValue)
                        }
                    }

                HStack {
                    // Total label
                    Text("Total \(backendViewModel.currentTotal.formatAsDollars())")
                    Spacer()
                }
                .padding()

                // Confirm Payment button
                Button(action: {
                    Task {
                        isConfirming = true
                        self.confirmationResult = await embeddedViewModel.confirm()
                        isConfirming = false
                    }
                }) {
                    if embeddedViewModel.paymentOption == nil {
                        Text("Select a payment method")
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Confirm Payment")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(embeddedViewModel.paymentOption == nil)
                .padding()
                .foregroundColor(.white)
                .background(
                    embeddedViewModel.paymentOption == nil
                    ? Color.gray
                    : Color.blue
                )
                .cornerRadius(6)
                #if DEBUG
                // Test height change button
                Button(action: {
                    embeddedViewModel.testHeightChange()
                }) {
                    Text("Test height change")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.orange)
                .cornerRadius(6)
                #endif
            } else if loadFailed {
                // Show a reload prompt if loading failed
                VStack(spacing: 16) {
                    Text("Failed to load Payment Element.")
                    Button("Try Again") {
                        Task {
                            await prepareEmbeddedPaymentElement()
                        }
                    }
                }
            } else {
                if !embeddedViewModel.isLoaded {
                    ProgressView("Preparing Payment...")
                }
            }
        }
        .padding()
        .task {
            Task {
                if !embeddedViewModel.isLoaded {
                    await prepareEmbeddedPaymentElement()
                }
            }
        }
        // Payment result alert
        .alert(
            alertTitle,
            isPresented: Binding<Bool>(
                get: { confirmationResult != nil },
                set: { if !$0 { confirmationResult = nil } }
            ),
            actions: {
                Button("Ok") {
                    dismiss()
                }
            },
            message: {
                Text(alertMessage)
            }
        )
        .allowsHitTesting(!isConfirming) // Disable user interaction during confirmation
    }

    private func prepareEmbeddedPaymentElement() async {
        // 1) Fetch ephemeral keys + initial total from /checkout
        guard let response = try? await backendViewModel.loadCheckout() else { return }

        // 2) Make the initial IntentConfiguration
        let intentConfig = backendViewModel.makeIntentConfiguration(isSubscribing: isSubscribing)

        // 3) Create the EmbeddedPaymentElement
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.allowsDelayedPaymentMethods = true
        configuration.applePay = .init(
            merchantId: "merchant.com.stripe.umbrella.test",
            merchantCountryCode: "US"
        )

        // Set the customer ID & ephemeral key from the backendViewModel
        configuration.customer = .init(
            id: response.customerID,
            ephemeralKeySecret: response.ephemeralKey
        )
        configuration.returnURL = "payments-example://stripe-redirect"

        do {
            try await embeddedViewModel.load(intentConfiguration: intentConfig, configuration: configuration)
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    /// Called whenever the user toggles subscription
    @MainActor
    private func handleSubscriptionToggle(_ newValue: Bool) async {
        // 1) Fetch updated totals from /compute_totals
        try? await backendViewModel.fetchUpdatedTotal(isSubscribing: newValue)

        // 2) Create a new IntentConfiguration with the updated total & subscription usage
        let updatedConfig = backendViewModel.makeIntentConfiguration(isSubscribing: newValue)

        // 3) Update the existing embedded payment element
        let result = await embeddedViewModel.update(intentConfiguration: updatedConfig)

        switch result {
        case .succeeded:
            print("Payment element updated with new total = \(backendViewModel.currentTotal)")
        case .canceled:
            print("Update was canceled by a subsequent call to `update`.")
        case .failed(let error):
            print("Update failed with error: \(error)")
        }
    }

    // MARK: - Alert
    var alertTitle: String {
        switch confirmationResult {
        case .completed: return "Success"
        case .failed:    return "Error"
        case .canceled:  return "Cancelled"
        case .none:      return ""
        }
    }

    var alertMessage: String {
        switch confirmationResult {
        case .completed:
            return "Payment completed!"
        case .failed(let error):
            return "Payment failed with error: \(error.localizedDescription)"
        case .canceled:
            return "Payment canceled by user."
        case .none:
            return ""
        }
    }
}

extension Int {
    func formatAsDollars() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(self) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Preview
@available(iOS 15.0, *)
struct MyEmbeddedCheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        MyEmbeddedCheckoutView()
    }
}
