//
//  CheckoutPlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import SwiftUI

struct CheckoutPlaygroundView: View {
    @StateObject private var viewModel = CheckoutPlayground.ViewModel()
    @State private var showCurrencySelectorAppearance = false

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
                            integrationType: $viewModel.integrationType,
                            currency: $viewModel.currency,
                            customerType: $viewModel.customerType,
                            checkoutEndpointOption: $viewModel.checkoutEndpointOption,
                            checkoutEndpoint: $viewModel.checkoutEndpoint
                        )

                        CheckoutPlaygroundLineItemsSection(
                            lineItems: viewModel.lineItems,
                            currency: viewModel.currency
                        )

                        CheckoutPlaygroundFeaturesSection(
                            customerType: viewModel.customerType,
                            shippingAddressCollection: $viewModel.shippingAddressCollection,
                            billingAddressCollection: $viewModel.billingAddressCollection,
                            allowPromotionCodes: $viewModel.allowPromotionCodes,
                            automaticTax: $viewModel.automaticTax,
                            adaptivePricing: $viewModel.adaptivePricing,
                            checkoutSessionPaymentMethodSave: $viewModel.checkoutSessionPaymentMethodSave,
                            checkoutSessionPaymentMethodRemove: $viewModel.checkoutSessionPaymentMethodRemove,
                            adaptivePricingCountry: $viewModel.adaptivePricingCountry,
                            automaticPaymentMethods: $viewModel.automaticPaymentMethods
                        )

                        if viewModel.adaptivePricing {
                            currencySelectorAppearanceSection
                        }

                        if !viewModel.automaticPaymentMethods {
                            CheckoutPlaygroundPaymentMethodSection(
                                selectedMethods: $viewModel.paymentMethodTypes,
                                availableMethods: CheckoutPlayground.ViewModel.availablePaymentMethods
                            )
                        }

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
                    CheckoutCartView(
                        clientSecret: clientSecret,
                        shippingAddressCollection: viewModel.shippingAddressCollection,
                        adaptivePricing: viewModel.adaptivePricing,
                        integrationType: viewModel.integrationType,
                        currencySelectorAppearance: viewModel.currencySelectorAppearance
                    )
                }
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
        }
    }

    @ViewBuilder
    private var currencySelectorAppearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CheckoutPlayground.SectionHeader(title: "Currency Selector", icon: "paintbrush.fill")
            Button {
                showCurrencySelectorAppearance = true
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                        .frame(width: 24)
                        .foregroundColor(.blue)
                    Text("Customize Appearance")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
