//
//  CheckoutPlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import SwiftUI

@available(iOS 15.0, *)
struct CheckoutPlaygroundView: View {
    @StateObject private var viewModel = CheckoutPlayground.ViewModel()

    var body: some View {
        Group {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if let error = viewModel.errorMessage {
                            CheckoutPlayground.ErrorBanner(message: error) {
                                viewModel.errorMessage = nil
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        CheckoutPlaygroundConfigurationSection(
                            mode: $viewModel.mode,
                            currency: $viewModel.currency,
                            customerType: $viewModel.customerType,
                            checkoutEndpointOption: $viewModel.checkoutEndpointOption,
                            checkoutEndpoint: $viewModel.checkoutEndpoint
                        )

                        if viewModel.mode != .setup {
                            CheckoutPlaygroundLineItemsSection(
                                lineItems: viewModel.lineItems,
                                currency: viewModel.currency
                            )
                        }

                        CheckoutPlaygroundFeaturesSection(
                            mode: viewModel.mode,
                            customerType: viewModel.customerType,
                            enableShipping: $viewModel.enableShipping,
                            shippingAddressCollection: $viewModel.shippingAddressCollection,
                            billingAddressCollection: $viewModel.billingAddressCollection,
                            phoneNumberCollection: $viewModel.phoneNumberCollection,
                            allowPromotionCodes: $viewModel.allowPromotionCodes,
                            automaticTax: $viewModel.automaticTax,
                            adaptivePricing: $viewModel.adaptivePricing,
                            checkoutSessionPaymentMethodSave: $viewModel.checkoutSessionPaymentMethodSave,
                            checkoutSessionPaymentMethodRemove: $viewModel.checkoutSessionPaymentMethodRemove,
                            adaptivePricingCountry: $viewModel.adaptivePricingCountry
                        )

                        CheckoutPlaygroundPaymentMethodSection(
                            selectedMethods: $viewModel.paymentMethodTypes,
                            availableMethods: CheckoutPlayground.ViewModel.availablePaymentMethods
                        )

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }

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
            .sheet(isPresented: $viewModel.navigateToCheckout) {
                if let clientSecret = viewModel.clientSecret {
                    CheckoutCartView(clientSecret: clientSecret, adaptivePricing: viewModel.adaptivePricing)
                }
            }
        }
    }
}
