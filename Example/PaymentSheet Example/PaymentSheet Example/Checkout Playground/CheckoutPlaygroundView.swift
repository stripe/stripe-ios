//
//  CheckoutPlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import SwiftUI

struct CheckoutPlaygroundView: View {
    @StateObject private var viewModel: CheckoutPlayground.ViewModel
    @State private var showCurrencySelectorAppearance = false
    @State private var showPaymentElementAppearance = false
    @State private var showExportQRCode = false

    init(settings: CheckoutPlayground.Settings? = nil, errorMessage: String? = nil) {
        let viewModel = CheckoutPlayground.ViewModel(settings: settings)
        viewModel.errorMessage = errorMessage
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        if let error = viewModel.errorMessage {
                            CheckoutPlayground.ErrorBanner(message: error) {
                                viewModel.errorMessage = nil
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        CheckoutPlaygroundSessionSection(viewModel: viewModel)
                        CheckoutPlaygroundClientSection(viewModel: viewModel)
                        CheckoutPlaygroundElementsSection(
                            viewModel: viewModel,
                            onCustomizePaymentElementAppearance: { showPaymentElementAppearance = true },
                            onCustomizeCurrencySelectorAppearance: { showCurrencySelectorAppearance = true }
                        )
                        CheckoutPlaygroundHarnessSection(viewModel: viewModel)

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .disabled(viewModel.isCreating)

                CheckoutPlayground.CreateButtonBar(
                    isCreating: viewModel.isCreating,
                    isDisabled: viewModel.isButtonDisabled
                ) {
                    Task {
                        await viewModel.createSession()
                    }
                }
            }
            .navigationTitle("Checkout Playground")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("QR") {
                        showExportQRCode = true
                    }
                    .accessibilityLabel("Export settings as QR code")
                    Button("Reset", action: viewModel.reset)
                }
            }
            .sheet(isPresented: $showExportQRCode) {
                if let exportURL = viewModel.exportURL {
                    QRView(url: exportURL)
                } else {
                    Text("Couldn't export settings.")
                }
            }
            .sheet(isPresented: $viewModel.navigateToCheckout) {
                if let clientSecret = viewModel.clientSecret {
                    switch viewModel.uiFramework {
                    case .swiftUI:
                        CheckoutCartView(
                            clientSecret: clientSecret,
                            emailSettings: viewModel.resolvedEmail,
                            shippingAddressCollection: viewModel.shippingAddressCollection,
                            defaultShippingAddress: viewModel.defaultShippingAddress,
                            defaultBillingAddress: viewModel.defaultBillingAddress,
                            defaultPhone: viewModel.resolvedDefaultPhone,
                            adaptivePricing: true,
                            integrationType: viewModel.integrationType,
                            expressCheckoutElementSettings: viewModel.expressCheckoutElement,
                            applePayEnabled: viewModel.applePayEnabled,
                            paymentElementApplePayDisplay: viewModel.paymentElementApplePayDisplay,
                            currencySelectorAppearance: viewModel.currencySelectorAppearance,
                            paymentElementAppearance: viewModel.paymentElementAppearance,
                            delayCheckoutClientRequests: viewModel.delayCheckoutClientRequests
                        )
                    case .uiKit:
                        CheckoutCartUIKitView(
                            clientSecret: clientSecret,
                            emailSettings: viewModel.resolvedEmail,
                            shippingAddressCollection: viewModel.shippingAddressCollection,
                            defaultShippingAddress: viewModel.defaultShippingAddress,
                            defaultBillingAddress: viewModel.defaultBillingAddress,
                            defaultPhone: viewModel.resolvedDefaultPhone,
                            adaptivePricing: true,
                            integrationType: viewModel.integrationType,
                            expressCheckoutElementSettings: viewModel.expressCheckoutElement,
                            applePayEnabled: viewModel.applePayEnabled,
                            paymentElementApplePayDisplay: viewModel.paymentElementApplePayDisplay,
                            currencySelectorAppearance: viewModel.currencySelectorAppearance,
                            paymentElementAppearance: viewModel.paymentElementAppearance,
                            delayCheckoutClientRequests: viewModel.delayCheckoutClientRequests
                        )
                    }
                }
            }
            .sheet(isPresented: $showPaymentElementAppearance) {
                AppearancePlaygroundView(
                    appearance: viewModel.paymentElementAppearance,
                    doneAction: { updatedAppearance in
                        viewModel.paymentElementAppearance = updatedAppearance
                        showPaymentElementAppearance = false
                    }
                )
            }
            .sheet(isPresented: $showCurrencySelectorAppearance) {
                CurrencySelectorAppearancePlaygroundView(
                    appearance: viewModel.currencySelectorAppearance,
                    doneAction: { updatedAppearance in
                        viewModel.currencySelectorAppearance = updatedAppearance
                        showCurrencySelectorAppearance = false
                    }
                )
            }
            .onAppear {
                viewModel.activateLinkModeOverride()
            }
            .onDisappear {
                viewModel.deactivateLinkModeOverride()
            }
        }
    }
}
