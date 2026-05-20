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
    }
}

// MARK: - Model

private class DesignCanvasModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var result: PaymentSheetResult?

    private let backendURL = URL(string: "https://stripe-mobile-payment-sheet.stripedemos.com/checkout")!

    func prepare() {
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let customerId = json["customer"] as? String,
                let ephemeralKey = json["ephemeralKey"] as? String,
                let clientSecret = json["paymentIntent"] as? String,
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
