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
    @StateObject private var diagnostics = CheckoutSessionDiagnostics()

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var eceConfirmResult: Checkout.ConfirmResult?
    @State private var showsCheckoutDetails = false

    let clientSecret: String
    let shippingAddressCollection: Bool
    let adaptivePricing: Bool
    let integrationType: CheckoutPlayground.IntegrationType
    var showExpressCheckoutElement: Bool = false
    var eceBillingDetailsCollectionConfiguration = ExpressCheckoutElement.BillingDetailsCollectionConfiguration()
    var currencySelectorAppearance = CurrencySelectorElement.Appearance()
    var delayPaymentPagesRequests = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                if let checkout {
                    CheckoutCartContentView(
                        checkout: checkout,
                        showsShippingAddressSection: shippingAddressCollection,
                        errorMessage: errorMessage
                    )
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 0) {
                            if showExpressCheckoutElement {
                                let ece = checkout.getExpressCheckoutElement { result in
                                    eceConfirmResult = result
                                }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showsCheckoutDetails = true
                    } label: {
                        Image(systemName: "ladybug")
                    }
                    .disabled(checkout == nil)
                    .opacity(checkout == nil ? 0 : 1)
                    .accessibilityLabel("Session diagnostics")
                }
            }
            .sheet(isPresented: $showsCheckoutDetails) {
                if let checkout {
                    CheckoutSessionDetailsView(
                        diagnostics: diagnostics,
                        sessionID: checkout.session.id
                    )
                }
            }
            .task {
                await loadCheckout()
            }
            .alert(
                eceConfirmResultAlertTitle,
                isPresented: Binding(get: { eceConfirmResult != nil }, set: { if !$0 { eceConfirmResult = nil } }),
                actions: { Button("OK") { eceConfirmResult = nil } },
                message: { Text(eceConfirmResultAlertMessage) }
            )
        }
    }

    private var eceConfirmResultAlertTitle: String {
        switch eceConfirmResult {
        case .succeeded: return "Success"
        case .canceled: return "Canceled"
        case .failed: return "Failed"
        case nil: return ""
        }
    }

    private var eceConfirmResultAlertMessage: String {
        switch eceConfirmResult {
        case .succeeded(let paymentStatus): return "Payment status: \(paymentStatus)"
        case .canceled: return "The payment was canceled."
        case .failed(let error): return error.localizedDescription
        case nil: return ""
        }
    }

    private func loadCheckout() async {
        isLoading = true
        errorMessage = nil
        do {
            var config = Checkout.Configuration(clientSecret: clientSecret, returnURL: "payments-example://stripe-redirect")
            config.apiClient = diagnostics.makeAPIClient(
                paymentPagesRequestDelay: delayPaymentPagesRequests ? 1 : 0
            )
            config.adaptivePricing.allowed = adaptivePricing
            config.currencySelectorElement.appearance = currencySelectorAppearance
            var expressCheckoutElementConfig = ExpressCheckoutElement.Configuration()
            expressCheckoutElementConfig.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.paymentsheet.example"
            )
            expressCheckoutElementConfig.billingDetailsCollectionConfiguration = eceBillingDetailsCollectionConfiguration
            config.expressCheckoutElement = expressCheckoutElementConfig
            config.shippingAddressElement.title = "Shipping Address"
            config.shippingAddressElement.buttonTitle = "Save Address"
            checkout = try await Checkout(configuration: config)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
