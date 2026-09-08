//
//  CheckoutPlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import SwiftUI

struct CheckoutPlaygroundView: View {
    @StateObject private var viewModel = CheckoutPlayground.ViewModel()
    @State private var showCurrencySelectorAppearance = false
    @State private var showBillingDetailsCollection = false
    @State private var showScenarios = false

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

                        scenarioLauncher

                        CheckoutPlaygroundConfigurationSection(
                            uiFramework: $viewModel.uiFramework,
                            integrationType: $viewModel.integrationType,
                            merchantCountry: $viewModel.merchantCountry,
                            currency: $viewModel.currency,
                            customerType: $viewModel.customerType,
                            checkoutEndpointOption: $viewModel.checkoutEndpointOption,
                            checkoutEndpoint: $viewModel.checkoutEndpoint,
                            delayPaymentPagesRequests: $viewModel.delayPaymentPagesRequests,
                            onReset: viewModel.reset
                        )

                        CheckoutPlaygroundLineItemsSection(
                            lineItems: viewModel.lineItems,
                            currency: viewModel.currency
                        )

                        CheckoutPlaygroundFeaturesSection(
                            customerType: viewModel.customerType,
                            shippingAddressCollection: $viewModel.shippingAddressCollection,
                            defaultShippingAddressOption: $viewModel.defaultShippingAddressOption,
                            customDefaultShippingAddress: $viewModel.customDefaultShippingAddress,
                            billingAddressCollection: $viewModel.billingAddressCollection,
                            automaticTax: $viewModel.automaticTax,
                            checkoutSessionPaymentMethodSave: $viewModel.checkoutSessionPaymentMethodSave,
                            checkoutSessionPaymentMethodRemove: $viewModel.checkoutSessionPaymentMethodRemove,
                            automaticPaymentMethods: $viewModel.automaticPaymentMethods,
                            showsWalletsInPaymentElement: $viewModel.showsWalletsInPaymentElement,
                            linkMode: $viewModel.linkMode
                        )

                        CheckoutPlaygroundExpressCheckoutElementSection(
                            showExpressCheckoutElement: $viewModel.expressCheckoutElement.isEnabled,
                            applePayDisplay: $viewModel.expressCheckoutElement.applePayDisplay,
                            linkDisplay: $viewModel.expressCheckoutElement.linkDisplay,
                            shippingAddressRequired: $viewModel.expressCheckoutElement.shippingAddressRequired,
                            onCustomizeBillingDetailsCollection: {
                                showBillingDetailsCollection = true
                            }
                        )

                        currencySelectorAppearanceSection

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
                    switch viewModel.uiFramework {
                    case .swiftUI:
                        CheckoutCartView(
                            clientSecret: clientSecret,
                            shippingAddressCollection: viewModel.shippingAddressCollection,
                            defaultShippingAddress: viewModel.defaultShippingAddress,
                            adaptivePricing: viewModel.showsCurrencySelectorElement,
                            integrationType: viewModel.integrationType,
                            showsWalletsInPaymentElement: viewModel.showsWalletsInPaymentElement,
                            expressCheckoutElementSettings: viewModel.expressCheckoutElement,
                            currencySelectorAppearance: viewModel.currencySelectorAppearance,
                            delayPaymentPagesRequests: viewModel.delayPaymentPagesRequests
                        )
                    case .uiKit:
                        CheckoutCartUIKitView(
                            clientSecret: clientSecret,
                            shippingAddressCollection: viewModel.shippingAddressCollection,
                            defaultShippingAddress: viewModel.defaultShippingAddress,
                            adaptivePricing: viewModel.showsCurrencySelectorElement,
                            integrationType: viewModel.integrationType,
                            showsWalletsInPaymentElement: viewModel.showsWalletsInPaymentElement,
                            expressCheckoutElementSettings: viewModel.expressCheckoutElement,
                            currencySelectorAppearance: viewModel.currencySelectorAppearance,
                            delayPaymentPagesRequests: viewModel.delayPaymentPagesRequests
                        )
                    }
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
            .sheet(isPresented: $showBillingDetailsCollection) {
                ExpressCheckoutElementBillingDetailsCollectionPlaygroundView(
                    configuration: viewModel.expressCheckoutElement.billingDetailsCollectionConfiguration,
                    doneAction: { updatedConfiguration in
                        viewModel.expressCheckoutElement.billingDetailsCollectionConfiguration = updatedConfiguration
                        showBillingDetailsCollection = false
                    }
                )
            }
            .sheet(isPresented: $showScenarios) {
                CheckoutPlaygroundScenarioView(groups: CheckoutPlayground.ScenarioCatalog.groups) { scenario in
                    viewModel.apply(scenario)
                    Task {
                        await viewModel.createSession()
                    }
                }
            }
            .onAppear {
                viewModel.activateLinkModeOverride()
            }
            .onDisappear {
                viewModel.deactivateLinkModeOverride()
            }
        }
    }

    @ViewBuilder
    private var currencySelectorAppearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CheckoutPlayground.SectionHeader(title: "Currency Selector", icon: "paintbrush.fill")
            VStack(spacing: 1) {
                CheckoutPlayground.ToggleRow(
                    title: "Show Currency Selector",
                    isOn: $viewModel.showsCurrencySelectorElement
                )

                if viewModel.showsCurrencySelectorElement {
                    CheckoutPlayground.AdaptivePricingLocationRow(
                        selection: $viewModel.adaptivePricingCountry
                    )

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
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var scenarioLauncher: some View {
        Button {
            showScenarios = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Run a scenario")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("Choose a repeatable test preset")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isCreating)
        .accessibilityIdentifier("checkout_scenarios")
    }
}
