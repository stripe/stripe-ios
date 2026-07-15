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
                                CheckoutCartPaymentButton(checkout: checkout)
                            case .embedded:
                                CheckoutCartEmbeddedPaymentView(checkout: checkout)
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
            var config = Checkout.Configuration(clientSecret: clientSecret)
            config.adaptivePricing.allowed = adaptivePricing
            config.paymentElement.billingDetailsCollectionConfiguration.name = .always
            config.paymentElement.billingDetailsCollectionConfiguration.address = .full
            checkout = try await Checkout(configuration: config)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
