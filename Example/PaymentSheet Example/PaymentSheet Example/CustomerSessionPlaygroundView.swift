//
//  CustomerSessionPlaygroundView.swift
//  PaymentSheet Example
//

import StripePaymentSheet

import SwiftUI

struct CustomerSessionPlaygroundView: View {
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

        var paymentMethodRedisplayBinding: Binding<PaymentSheetTestPlaygroundSettings.PaymentMethodRedisplay> {
            Binding<PaymentSheetTestPlaygroundSettings.PaymentMethodRedisplay> {
                return viewModel.paymentMethodRedisplay
            } set: { newPaymentMethodRedisplay in
                if viewModel.paymentMethodRedisplay.rawValue != newPaymentMethodRedisplay.rawValue {
                    viewModel.paymentMethodAllowRedisplayFilters = .notSet
                }
                    viewModel.paymentMethodRedisplay = newPaymentMethodRedisplay
            }
        }

        VStack {
            HStack {
                Text("Customer Session")
                    .font(.title)
                    .bold()
                Spacer()
                Button("Done") {
                    doneAction(viewModel)
                }
            }.padding()
            Group {
                VStack {
                    SettingPickerView(setting: paymentMethodSaveBinding)
                    if viewModel.paymentMethodSave == .disabled {
                        SettingPickerView(setting: $viewModel.allowRedisplayOverride)
                    } else {
                        SettingPickerView(setting: $viewModel.paymentMethodSetAsDefault)
                    }
                    SettingPickerView(setting: $viewModel.paymentMethodRemove)
                    SettingPickerView(setting: $viewModel.paymentMethodRemoveLast)
                    SettingPickerView(setting: paymentMethodRedisplayBinding)
                    if viewModel.paymentMethodRedisplay == .enabled {
                        SettingPickerView(setting: $viewModel.paymentMethodAllowRedisplayFilters)
                    }
                }
            }.padding()

        }
    }
}
