import SwiftUI
@_spi(EmbeddedPaymentElementPrivateBeta) import StripePaymentSheet

// MARK: - BackendViewModel
class BackendViewModel: ObservableObject {
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!

    @MainActor
    func prepareEmbeddedPaymentElement() async -> EmbeddedPaymentElement? {
        do {
            let response = try await fetchPaymentIntentFromBackend()
            STPAPIClient.shared.publishableKey = response.publishableKey

            var configuration = EmbeddedPaymentElement.Configuration()
            configuration.merchantDisplayName = "Example, Inc."
            configuration.allowsDelayedPaymentMethods = true
            configuration.applePay = .init(
                merchantId: "merchant.com.stripe.umbrella.test",
                merchantCountryCode: "US"
            )
            configuration.customer = .init(
                id: response.customerID,
                ephemeralKeySecret: response.ephemeralKey
            )
            configuration.returnURL = "payments-example://stripe-redirect"

            let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 973, currency: "EUR")) { paymentMethod, shouldSavePaymentMethod, intentCreationCallback in
                intentCreationCallback(.success(response.paymentIntentClientSecret))
            }

            let element = try await EmbeddedPaymentElement.create(
                intentConfiguration: intentConfig,
                configuration: configuration
            )

            return element

        } catch {
            print("Error while preparing PaymentSheet: \(error)")
        }
        
        return nil
    }

    private func fetchPaymentIntentFromBackend() async throws -> BackendResponse {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard
            let json = json,
            let customerId = json["customer"] as? String,
            let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
            let paymentIntentClientSecret = json["paymentIntent"] as? String,
            let publishableKey = json["publishableKey"] as? String
        else {
            throw URLError(.badServerResponse)
        }

        return BackendResponse(
            publishableKey: publishableKey,
            paymentIntentClientSecret: paymentIntentClientSecret,
            customerID: customerId,
            ephemeralKey: customerEphemeralKeySecret
        )
    }

    struct BackendResponse {
        let publishableKey: String
        let paymentIntentClientSecret: String
        let customerID: String
        let ephemeralKey: String
    }
}

// MARK: - SwiftUI Checkout View
@available(iOS 15.0, *)
struct MyEmbeddedCheckoutView: View {
    @StateObject var backendViewModel = BackendViewModel()
    @StateObject var embeddedViewModel = EmbeddedPaymentElementView.ViewModel()
    @State private var paymentResult: PaymentSheetResult?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            if embeddedViewModel.embeddedPaymentElement != nil {
                ScrollView {
                    // Embedded Payment Element
                    EmbeddedPaymentElementView(viewModel: embeddedViewModel)
                        .frame(height: embeddedViewModel.height)
                    
                    // Payment option row
                    if let paymentOption = embeddedViewModel.embeddedPaymentElement?.paymentOption {
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
                    // Confirm Payment button
                    Button(action: {
                        Task {
                            paymentResult = await embeddedViewModel.embeddedPaymentElement?.confirm()
                        }
                    }) {
                        if embeddedViewModel.embeddedPaymentElement == nil {
                            ProgressView()
                        } else {
                            Text("Confirm Payment")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(
                        embeddedViewModel.embeddedPaymentElement == nil
                        || embeddedViewModel.embeddedPaymentElement?.paymentOption == nil
                    )
                    .padding()
                    .foregroundColor(.white)
                    .background(embeddedViewModel.embeddedPaymentElement?.paymentOption == nil ? Color.gray : Color.blue)
                    .cornerRadius(6)
                    
                    // Test height change button
                    Button(action: {
                        embeddedViewModel.embeddedPaymentElement?.testHeightChange()
                    }) {
                        Text("Test height change")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(6)
                }
            } else {
                if embeddedViewModel.embeddedPaymentElement == nil {
                    ProgressView("Preparing Payment...")
                } else {
                    Text("Payment element not loaded.")
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                embeddedViewModel.embeddedPaymentElement = await backendViewModel.prepareEmbeddedPaymentElement()
            }
        }
        .alert(
            alertTitle,
            isPresented: Binding<Bool>(
                get: { paymentResult != nil },
                set: { if !$0 { paymentResult = nil } }
            ),
            actions: {
                Button("OK") {
                    dismiss()
                }
            },
            message: {
                Text(alertMessage)
            }
        )
    }
    
    var alertTitle: String {
        switch paymentResult {
        case .completed:
            return "Success"
        case .failed:
            return "Error"
        case .canceled:
            return "Cancelled"
        case .none:
            return ""
        }
    }
    
    var alertMessage: String {
        switch paymentResult {
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

// MARK: - SwiftUI Preview
@available(iOS 15.0, *)
struct MyEmbeddedCheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        MyEmbeddedCheckoutView()
    }
}
