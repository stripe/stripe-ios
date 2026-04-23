//
//  ExampleSwiftUIPaymentSheet.swift
//  PaymentSheet Example
//
//  Created by David Estes on 1/15/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import StripePaymentSheet
import SwiftUI

struct ExampleSwiftUIPaymentSheet: View {
    @ObservedObject var model = MyBackendModel()

    var body: some View {
        VStack {
            if let paymentSheet = model.paymentSheet {
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: model.onCompletion
                ) {
                    ExamplePaymentButtonView()
                }
            } else {
                ExampleLoadingView()
            }
            if let result = model.paymentResult {
                ExamplePaymentStatusView(result: result)
            }
        }.onAppear { model.preparePaymentSheet() }
    }

}

class MyBackendModel: ObservableObject {
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.stripedemos.com/checkout")!  // An example backend endpoint
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    func preparePaymentSheet() {
        Task {
            do {
                try await loadPaymentSheet()
            } catch {
                print("Failed to load checkout: \(error)")
            }
        }
    }

    private func loadPaymentSheet() async throws {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard
            let customerId = json?["customer"] as? String,
            let customerEphemeralKeySecret = json?["ephemeralKey"] as? String,
            let paymentIntentClientSecret = json?["paymentIntent"] as? String,
            let publishableKey = json?["publishableKey"] as? String
        else {
            throw NSError(domain: "ExampleError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from backend"])
        }
        // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
        STPAPIClient.shared.publishableKey = publishableKey

        // MARK: Create a PaymentSheet instance
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
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntentClientSecret,
            configuration: configuration)
    }

    func onCompletion(result: PaymentSheetResult) {
        self.paymentResult = result

        // MARK: Demo cleanup
        if case .completed = result {
            // A PaymentIntent can't be reused after a successful payment. Prepare a new one for the demo.
            self.paymentSheet = nil
            preparePaymentSheet()
        }
    }
}

struct ExampleSwiftUIPaymentSheet_Preview: PreviewProvider {
    static var previews: some View {
        ExampleSwiftUIPaymentSheet()
    }
}
