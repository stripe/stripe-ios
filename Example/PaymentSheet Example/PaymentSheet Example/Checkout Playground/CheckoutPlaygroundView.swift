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
        NavigationView {
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
                            customerType: $viewModel.customerType
                        )

                        if viewModel.mode != .setup {
                            CheckoutPlaygroundLineItemsSection(
                                lineItems: $viewModel.lineItems,
                                currency: viewModel.currency
                            )
                        }

                        CheckoutPlaygroundFeaturesSection(
                            mode: viewModel.mode,
                            enableShipping: $viewModel.enableShipping,
                            shippingAddressCollection: $viewModel.shippingAddressCollection,
                            billingAddressCollection: $viewModel.billingAddressCollection,
                            phoneNumberCollection: $viewModel.phoneNumberCollection,
                            allowPromotionCodes: $viewModel.allowPromotionCodes,
                            automaticTax: $viewModel.automaticTax
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
            .background(
                NavigationLink(
                    destination: Group {
                        if let clientSecret = viewModel.clientSecret {
                            Text("Checkout View Placeholder: \(clientSecret)")
                        }
                    },
                    isActive: $viewModel.navigateToCheckout
                ) { EmptyView() }
                    .hidden()
            )
        }
    }
}
