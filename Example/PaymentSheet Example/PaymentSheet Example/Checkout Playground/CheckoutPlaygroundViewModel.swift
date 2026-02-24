//
//  CheckoutPlaygroundViewModel.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
extension CheckoutPlayground {
    @MainActor
    final class ViewModel: ObservableObject {
        private static let backendUrl = URL(string: "http://127.0.0.1:8081/checkout_session")!

        static let availablePaymentMethods = [
            "card", "us_bank_account", "cashapp", "affirm", "klarna",
        ]

        @Published var mode: SessionMode = .payment
        @Published var currency: Currency = .usd
        @Published var customerType: CustomerType = .guest
        @Published var lineItems: [LineItemConfig] = LineItemConfig.defaults
        @Published var enableShipping = true
        @Published var allowPromotionCodes = true
        @Published var phoneNumberCollection = true
        @Published var shippingAddressCollection = true
        @Published var billingAddressCollection = false
        @Published var automaticTax = true
        @Published var paymentMethodTypes: Set<String> = ["card"]

        @Published var isCreating = false
        @Published var errorMessage: String?
        @Published var clientSecret: String?
        @Published var navigateToCheckout = false

        var isButtonDisabled: Bool {
            isCreating || paymentMethodTypes.isEmpty || (mode != .setup && lineItems.isEmpty)
        }

        func createSession() async {
            isCreating = true
            errorMessage = nil
            defer {
                isCreating = false
            }

            do {
                let body = buildRequestBody()
                var request = URLRequest(url: Self.backendUrl)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)
                let httpResponse = response as? HTTPURLResponse
                let responseString = String(data: data, encoding: .utf8) ?? "(not utf8)"
                print("[CheckoutPlayground] HTTP status: \(httpResponse?.statusCode ?? -1)")
                print("[CheckoutPlayground] Response body: \(responseString)")

                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let publishableKey = json["publishableKey"] as? String,
                      let clientSecret = json["checkoutSessionClientSecret"] as? String else {
                    throw NSError(domain: "CheckoutPlayground", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid backend response: \(responseString)",
                    ])
                }

                // Example app behavior: the local backend response controls the Stripe publishable key.
                STPAPIClient.shared.publishableKey = publishableKey
                self.clientSecret = clientSecret
                navigateToCheckout = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        private func buildRequestBody() -> [String: Any] {
            // The backend currently applies setup-mode restrictions for these fields.
            // Send explicit safe values so setup mode never requests unsupported options.
            let supportsAdvancedCollection = mode != .setup
            let allowPromotionCodesForRequest = supportsAdvancedCollection ? allowPromotionCodes : false
            let phoneNumberCollectionForRequest = supportsAdvancedCollection ? phoneNumberCollection : false
            let automaticTaxForRequest = supportsAdvancedCollection ? automaticTax : false

            var body: [String: Any] = [
                "mode": mode.rawValue,
                "currency": currency.rawValue,
                "customer": customerType.rawValue,
                "allow_promotion_codes": allowPromotionCodesForRequest,
                "phone_number_collection": phoneNumberCollectionForRequest,
                "shipping_address_collection": shippingAddressCollection,
                "billing_address_collection": billingAddressCollection,
                "include_shipping_options": enableShipping,
                "automatic_tax": automaticTaxForRequest,
                "payment_method_types": Array(paymentMethodTypes),
            ]

            if mode != .setup {
                body["line_items"] = lineItems.map { item -> [String: Any] in
                    [
                        "name": item.name,
                        "unit_amount": item.unitAmount,
                        "quantity": item.quantity,
                    ]
                }
            }

            return body
        }
    }
}
