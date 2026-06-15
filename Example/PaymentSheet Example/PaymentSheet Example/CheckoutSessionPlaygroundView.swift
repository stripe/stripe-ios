//
//  CheckoutSessionPlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 4/10/26.

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutSessionPlaygroundView: View {
    @State var viewModel: PaymentSheetTestPlaygroundSettings
    @Binding var currencySelectorAppearance: Checkout.CurrencySelectorView.Appearance
    @State private var showCurrencySelectorAppearance = false
    var doneAction: ((PaymentSheetTestPlaygroundSettings) -> Void) = { _ in }

    var body: some View {
        var paymentMethodSaveBinding: Binding<PaymentSheetTestPlaygroundSettings.PaymentMethodSave> {
            Binding<PaymentSheetTestPlaygroundSettings.PaymentMethodSave> {
                return viewModel.paymentMethodSave
            } set: { newValue in
                if viewModel.paymentMethodSave != newValue {
                    viewModel.allowRedisplayOverride = .notSet
                }
                viewModel.paymentMethodSave = newValue
            }
        }

        VStack {
            HStack {
                Text("Checkout Session")
                    .font(.title)
                    .bold()
                Spacer()
                Button("Done") {
                    doneAction(viewModel)
                }
            }.padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Saved Payment Methods
                    Group {
                        Text("Saved Payment Methods")
                            .font(.headline)
                        VStack {
                            SettingPickerView(setting: paymentMethodSaveBinding)
                            SettingPickerView(setting: $viewModel.paymentMethodRemove)
                        }
                    }

                    Divider()

                    // MARK: - Session Features
                    Group {
                        Text("Session Features")
                            .font(.headline)
                        VStack {
                            SettingView(setting: $viewModel.csAllowPromotionCodes)
                            SettingView(setting: $viewModel.csAutomaticTax)
                            SettingView(setting: $viewModel.csAdaptivePricing)
                            SettingView(setting: $viewModel.csDisplayShippingRates)
                            SettingView(setting: $viewModel.csAdjustableQuantity)
                            SettingView(setting: $viewModel.csManualCapture)
                        }
                    }

                    if viewModel.csAdaptivePricing == .on {
                        Divider()

                        // MARK: - Adaptive Pricing
                        Group {
                            Text("Adaptive Pricing")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Simulate Customer Country")
                                    .font(.subheadline)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Self.adaptivePricingCountries, id: \.code) { country in
                                            Button(country.label) {
                                                if country.code.isEmpty {
                                                    viewModel.csCustomerEmail = nil
                                                } else {
                                                    viewModel.csCustomerEmail = "test+location_\(country.code)@example.com"
                                                }
                                            }
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(isCountrySelected(country.code) ? Color.blue : Color.blue.opacity(0.1))
                                            .foregroundColor(isCountrySelected(country.code) ? .white : .blue)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }

                            Button("Customize Currency Selector Appearance") {
                                showCurrencySelectorAppearance = true
                            }
                        }
                        .sheet(isPresented: $showCurrencySelectorAppearance) {
                            CurrencySelectorAppearancePlaygroundView(
                                appearance: currencySelectorAppearance,
                                doneAction: { updatedAppearance in
                                    currencySelectorAppearance = updatedAppearance
                                    showCurrencySelectorAppearance = false
                                }
                            )
                        }
                    }

                    Divider()

                    // MARK: - Advanced
                    Group {
                        Text("Advanced")
                            .font(.headline)
                        VStack(spacing: 8) {
                            HStack {
                                Text("Customer Email")
                                    .font(.subheadline)
                                Spacer()
                            }
                            TextField("test@example.com", text: Binding(
                                get: { viewModel.csCustomerEmail ?? "" },
                                set: { viewModel.csCustomerEmail = $0.isEmpty ? nil : $0 }
                            ))
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                            HStack {
                                Text("Payment Method Configuration")
                                    .font(.subheadline)
                                Spacer()
                            }
                            TextField("pmc_...", text: Binding(
                                get: { viewModel.csPaymentMethodConfiguration ?? "" },
                                set: { viewModel.csPaymentMethodConfiguration = $0.isEmpty ? nil : $0 }
                            ))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private static let adaptivePricingCountries: [(label: String, code: String)] = [
        ("None", ""),
        ("US", "US"),
        ("DE", "DE"),
        ("JP", "JP"),
        ("GB", "GB"),
    ]

    private func isCountrySelected(_ code: String) -> Bool {
        guard let email = viewModel.csCustomerEmail else {
            return code.isEmpty
        }
        if code.isEmpty {
            return !email.contains("+location_")
        }
        return email.contains("+location_\(code)@")
    }
}
