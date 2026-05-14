//
//  CheckoutSessionPlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 4/10/26.

import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
struct CheckoutSessionPlaygroundView: View {
    @State var viewModel: PaymentSheetTestPlaygroundSettings
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
}
