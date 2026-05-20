import StripePaymentSheet
import SwiftUI

// MARK: - DesignCanvas
// This is the design prototyping canvas. It auto-presents the payment sheet on launch.
// When starting a new prototype, branch off `canvas` and modify this file.

@available(iOS 14.0, *)
struct DesignCanvas: View {
    @StateObject private var model = DesignCanvasModel()
    @State private var isPresented = false

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Merchant summary card ──────────────────────────────
                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .frame(height: 180)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "bag.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("Order Summary")
                                    .font(.headline)
                                Text("$49.99")
                                    .font(.system(size: 34, weight: .bold))
                            }
                        )
                        .padding(.horizontal, 24)

                    // ── Pay button ─────────────────────────────────────
                    if let paymentSheet = model.paymentSheet {
                        PaymentSheet.PaymentButton(
                            paymentSheet: paymentSheet,
                            onCompletion: model.onCompletion
                        ) {
                            Text("Checkout")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal, 24)
                        }
                    } else {
                        ProgressView()
                            .frame(height: 50)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            model.prepare()
        }
        .onChange(of: model.isReady) { ready in
            if ready { isPresented = true }
        }
        .paymentSheet(
            isPresented: $isPresented,
            paymentSheet: model.paymentSheet ?? PaymentSheet(paymentIntentClientSecret: "", configuration: .init()),
            onCompletion: model.onCompletion
        )
    }
}

// MARK: - Model

private class DesignCanvasModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var isReady: Bool = false
    @Published var result: PaymentSheetResult?

    private let backendURL = URL(string: "https://stp-mobile-playground-backend-v7.stripedemos.com/checkout")!

    func prepare() {
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "customer": "returning",
            "currency": "usd",
            "merchant_country_code": "US",
            "mode": "payment",
            "automatic_payment_methods": true,
        ])
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let customerId = json["customerId"] as? String,
                let ephemeralKey = json["customerEphemeralKeySecret"] as? String,
                let clientSecret = json["intentClientSecret"] as? String,
                let publishableKey = json["publishableKey"] as? String
            else { return }

            STPAPIClient.shared.publishableKey = publishableKey

            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "Design Canvas"
            config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
            config.applePay = .init(merchantId: "merchant.com.stripe.umbrella.test", merchantCountryCode: "US")
            config.returnURL = "payments-example://stripe-redirect"
            config.allowsDelayedPaymentMethods = true

            DispatchQueue.main.async {
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: clientSecret,
                    configuration: config
                )
                self.isReady = true
            }
        }.resume()
    }

    func onCompletion(result: PaymentSheetResult) {
        self.result = result
        if case .completed = result {
            paymentSheet = nil
            prepare()
        }
    }
}
