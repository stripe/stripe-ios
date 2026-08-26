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
    @State private var checkout: CheckoutController?
    @StateObject private var diagnostics = CheckoutSessionDiagnostics()

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var confirmResult: CheckoutController.ConfirmResult?
    @State private var showsCheckoutDetails = false

    let clientSecret: String
    let shippingAddressCollection: Bool
    let defaultShippingAddress: CheckoutPlayground.DefaultShippingAddress?
    let adaptivePricing: Bool
    let integrationType: CheckoutPlayground.IntegrationType
    var showExpressCheckoutElement: Bool = false
    var applePayDisplay: ExpressCheckoutElement.ApplePayConfiguration.Display = .automatic
    var linkDisplay: ExpressCheckoutElement.LinkConfiguration.Display = .automatic
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
                        showsShippingAddressSection: shippingAddressCollection || checkout.session.shippingAddress != nil,
                        errorMessage: errorMessage
                    )
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        VStack(spacing: 0) {
                            if showExpressCheckoutElement,
                               let ece = checkout.getExpressCheckoutElement() {
                                ece.view
                                    .padding(.horizontal)
                                    .padding(.top, 16)
                            }
                            switch integrationType {
                            case .flowController:
                                CheckoutCartPaymentButton(checkout: checkout) { result in
                                    confirmResult = result
                                }
                                    .clipped()
                            case .embedded:
                                CheckoutCartEmbeddedPaymentView(checkout: checkout) { result in
                                    confirmResult = result
                                }
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
                        checkout: checkout
                    )
                }
            }
            .task {
                await loadCheckout()
            }
            .alert(
                confirmResultAlertTitle,
                isPresented: Binding(get: { confirmResult != nil }, set: { if !$0 { confirmResult = nil } }),
                actions: { Button("OK") { acknowledgeConfirmResult() } },
                message: { Text(confirmResultAlertMessage) }
            )
        }
        .disabled(checkout?.isUpdating == true)
    }

    private var confirmResultAlertTitle: String {
        switch confirmResult {
        case .succeeded: return "Success"
        case .canceled: return "Canceled"
        case .failed: return "Unable to complete checkout"
        case nil: return ""
        }
    }

    private var confirmResultAlertMessage: String {
        switch confirmResult {
        case .succeeded(let paymentStatus): return "Payment status: \(paymentStatus)"
        case .canceled: return "The payment was canceled."
        case .failed(let error):
            return "Localized: \(error.localizedDescription)\n\nDebug: \(String(reflecting: error))"
        case nil: return ""
        }
    }

    private func acknowledgeConfirmResult() {
        let confirmationSucceeded: Bool
        if case .succeeded = confirmResult {
            confirmationSucceeded = true
        } else {
            confirmationSucceeded = false
        }
        confirmResult = nil
        if confirmationSucceeded {
            dismiss()
        }
    }

    private func loadCheckout() async {
        isLoading = true
        errorMessage = nil
        do {
            var config = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "payments-example://stripe-redirect")
            config.apiClient = diagnostics.makeAPIClient(
                paymentPagesRequestDelay: delayPaymentPagesRequests ? 1 : 0
            )
            config.adaptivePricing.allowed = adaptivePricing
            config.defaults.shippingDetails = defaultShippingAddress?.checkoutShippingDetails
            config.applePayConfiguration = CheckoutController.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.paymentsheet.example"
            )
            config.currencySelectorElement.appearance = currencySelectorAppearance
            config.expressCheckoutElement.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.paymentsheet.example",
                display: applePayDisplay
            )
            config.expressCheckoutElement.linkConfiguration = ExpressCheckoutElement.LinkConfiguration(display: linkDisplay)
            config.expressCheckoutElement.confirmHandler = { result in
                confirmResult = result
            }
            config.expressCheckoutElement.billingDetailsCollectionConfiguration = eceBillingDetailsCollectionConfiguration
            config.shippingAddressElement.title = "Shipping Address"
            config.shippingAddressElement.buttonTitle = "Save Address"
            checkout = try await CheckoutController(configuration: config)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
