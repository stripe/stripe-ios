//
//  CheckoutPlaygroundViewModel.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

@_spi(STP) import StripePaymentSheet
import SwiftUI

extension CheckoutPlayground {
    @MainActor
    final class ViewModel: ObservableObject {
        static let availablePaymentMethods = [
            "card", "us_bank_account", "cashapp", "affirm", "klarna",
        ]

        @Published var integrationType: IntegrationType = .flowController
        @Published var expressCheckoutElementOption: ExpressCheckoutElementOption = .disabled
        @Published var currency: Currency = .usd
        @Published var customerType: CustomerType = .guest
        @Published var lineItems: [LineItemConfig] = LineItemConfig.defaults
        @Published var allowPromotionCodes = true
        @Published var shippingAddressCollection = true
        @Published var billingAddressCollection: BillingAddressCollection = .automatic
        @Published var automaticTax = true
        @Published var adaptivePricing = false
        @Published var checkoutSessionPaymentMethodSave = true
        @Published var checkoutSessionPaymentMethodRemove = true
        @Published var adaptivePricingCountry: AdaptivePricingCountry = .none
        @Published var automaticPaymentMethods = false
        @Published var paymentMethodTypes: Set<String> = ["card"]
        @Published var currencySelectorAppearance = Checkout.CurrencySelectorView.Appearance()
        @Published var checkoutEndpointOption: EndpointOption = .hosted
        @Published var checkoutEndpoint = EndpointOption.hosted.endpoint ?? ""

        @Published var isCreating = false
        @Published var errorMessage: String?
        @Published var clientSecret: String?
        @Published var navigateToCheckout = false

        var isButtonDisabled: Bool {
            isCreating || (!automaticPaymentMethods && paymentMethodTypes.isEmpty) || lineItems.isEmpty
        }

        func createSession() async {
            isCreating = true
            errorMessage = nil
            defer {
                isCreating = false
            }

            do {
                guard let backendURL = URL(string: checkoutEndpoint) else {
                    throw NSError(domain: "CheckoutPlayground", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid endpoint URL: \(checkoutEndpoint)",
                    ])
                }
                let body = buildRequestBody()
                var request = URLRequest(url: backendURL)
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
            var body: [String: Any] = [
                "merchant_country_code": "us_tax",
                "currency": currency.rawValue,
                "customer": customerType.rawValue,
                "allow_promotion_codes": allowPromotionCodes,
                "shipping_address_collection": shippingAddressCollection,
                "billing_address_collection": billingAddressCollection == .required,
                "automatic_tax": automaticTax,
                "adaptive_pricing": adaptivePricing,
                "checkout_session_payment_method_save": checkoutSessionPaymentMethodSave ? "enabled" : "disabled",
                "checkout_session_payment_method_remove": checkoutSessionPaymentMethodRemove ? "enabled" : "disabled",
            ]
            if automaticPaymentMethods {
                body["automatic_payment_methods"] = true
            } else {
                body["payment_method_types"] = Array(paymentMethodTypes)
            }
            if adaptivePricing, adaptivePricingCountry != .none {
                let countryCode = adaptivePricingCountry.rawValue.uppercased()
                body["customer_email"] = "test+location_\(countryCode)@example.com"
            }

            return body
        }
    }
}
