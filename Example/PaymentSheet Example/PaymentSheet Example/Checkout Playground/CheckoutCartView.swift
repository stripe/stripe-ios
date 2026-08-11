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
    let shippingAddressCollection: Bool
    let adaptivePricing: Bool
    let integrationType: CheckoutPlayground.IntegrationType
    var showExpressCheckoutElement: Bool = false
    var applePayVisibility: CheckoutPlayground.WalletVisibilityOption = .auto
    var applePayButtonTypeOption: CheckoutPlayground.ApplePayButtonTypeOption = .plain
    var linkVisibility: CheckoutPlayground.WalletVisibilityOption = .auto
    var linkDisplayOption: CheckoutPlayground.LinkDisplayOption = .automatic
    var currencySelectorAppearance = CurrencySelectorElement.Appearance()

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                if let checkout {
                    CheckoutCartContentView(
                        checkout: checkout,
                        showsShippingAddressSection: shippingAddressCollection,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage
                    )
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 0) {
                            if checkout.session.total != nil {
                                if showExpressCheckoutElement,
                                   let ece = checkout.getExpressCheckoutElement() {
                                    ece.view
                                        .padding(.horizontal)
                                        .padding(.top, 16)
                                }
                                switch integrationType {
                                case .flowController:
                                    CheckoutCartPaymentButton(checkout: checkout)
                                        .clipped()
                                case .embedded:
                                    CheckoutCartEmbeddedPaymentView(checkout: checkout)
                                        .clipped()
                                case .eceOnly:
                                    EmptyView()
                                }
                            }
                        }
                        .background(
                            Color(UIColor.systemBackground)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                                .ignoresSafeArea()
                        )
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
            var config = Checkout.Configuration(clientSecret: clientSecret, returnURL: "payments-example://stripe-redirect")
            config.adaptivePricing.allowed = adaptivePricing
            config.applePayConfiguration = Checkout.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.paymentsheet.example",
                buttonType: applePayButtonTypeOption.pkButtonType
            )
            config.linkConfiguration = Checkout.LinkConfiguration(display: linkDisplayOption.linkDisplay)
            if showExpressCheckoutElement {
                config.expressCheckoutElement.paymentMethods.applePay = applePayVisibility.applePayVisibility
                config.expressCheckoutElement.paymentMethods.link = linkVisibility.linkVisibility
            }
            config.currencySelectorElement.appearance = currencySelectorAppearance
            checkout = try await Checkout(configuration: config)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
