//
//  CheckoutCartView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/2/26.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutCartView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var checkout: Checkout?

    @State private var isLoading = false
    @State private var errorMessage: String?

    let clientSecret: String
    let adaptivePricing: Bool
    let billingAddressCollection: Bool
    let allowPromotionCodes: Bool
    let integrationType: CheckoutPlayground.IntegrationType
    var currencySelectorAppearance = Checkout.CurrencySelectorView.Appearance()

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                if let checkout {
                    CheckoutCartContentView(
                        checkout: checkout,
                        currencySelectorAppearance: currencySelectorAppearance,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage
                    )
                    .overlay(alignment: .bottom) {
                        if checkout.session.total != nil {
                            switch integrationType {
                            case .flowController:
                                CheckoutCartPaymentButton(
                                    checkout: checkout,
                                    onDismiss: { dismiss() }
                                )
                            case .embedded:
                                CheckoutCartEmbeddedPaymentView(
                                    checkout: checkout,
                                    onDismiss: { dismiss() }
                                )
                            case .expressCheckout:
                                CheckoutCartExpressCheckoutView(
                                    checkout: checkout,
                                    onDismiss: { dismiss() }
                                )
                            }
                        }
                    }
                } else if isLoading {
                    ProgressView("Loading Cart...")
                } else {
                    VStack {
                        Text("Failed to load cart.")
                        Button("Retry") {
                            Task { await loadCheckout() }
                        }
                        .padding()
                    }
                }

                if isLoading && checkout != nil {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationTitle("Your Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                await loadCheckout()
            }
        }
    }

    private func loadCheckout() async {
        isLoading = true
        errorMessage = nil
        do {
            var config = Checkout.Configuration()
            config.adaptivePricing.allowed = adaptivePricing
            config.expressCheckout.returnURL = "payments-example://stripe-redirect"
            config.expressCheckout.applePay = PaymentSheet.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.umbrella.test",
                merchantCountryCode: "US"
            )
            if billingAddressCollection {
                config.expressCheckout.billingDetailsCollectionConfiguration.address = .full
            }
            config.expressCheckout.allowsPromotionCodes = allowPromotionCodes
            checkout = try await Checkout(clientSecret: clientSecret, configuration: config)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
