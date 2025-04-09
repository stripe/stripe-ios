//
//  PaymentMethodOptionsSetupFutureUsagePlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Joyce Qin on 4/8/25.
//

import StripePaymentSheet

import SwiftUI

struct PaymentMethodOptionsSetupFutureUsagePlaygroundView: View {
    @State var viewModel: PaymentSheetTestPlaygroundSettings
    var doneAction: ((PaymentSheetTestPlaygroundSettings) -> Void) = { _ in }

    var body: some View {
        VStack {
            HStack {
                Text("Payment Method Options Setup Future Usage")
                    .font(.title)
                    .bold()
                Spacer()
                Button("Done") {
                    doneAction(viewModel)
                }
            }.padding()
            Group {
                VStack {
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.card, customDisplayLabel: "Card")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.usBankAccount, customDisplayLabel: "US Bank Account")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.sepaDebit, customDisplayLabel: "SEPA Debit")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.link, customDisplayLabel: "Link")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.klarna, customDisplayLabel: "Klarna")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.affirm, customDisplayLabel: "Affirm")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.afterpayClearpay, customDisplayLabel: "Afterpay/Clearpay")
                    TextField("pm_type=sfu_value (comma separated)", text: customPaymentMethodOptionsSetupFutureUsageBinding)
                        .autocapitalization(.none)
                }
            }.padding()

        }
    }

    var customPaymentMethodOptionsSetupFutureUsageBinding: Binding<String> {
        Binding<String> {
            return viewModel.customPaymentMethodOptionsSetupFutureUsage ?? ""
        } set: { newString in
            viewModel.customPaymentMethodOptionsSetupFutureUsage = newString
        }
    }
}
