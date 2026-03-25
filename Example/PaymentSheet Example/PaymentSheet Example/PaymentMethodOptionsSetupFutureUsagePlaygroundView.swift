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
                    if viewModel.merchantCountryCode == .US, viewModel.currency == .usd, viewModel.allowsDelayedPMs == .on {
                        SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.usBankAccount, customDisplayLabel: "US Bank Account")
                    }
                    if viewModel.allowsDelayedPMs == .on, viewModel.currency == .eur {
                        SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.sepaDebit, customDisplayLabel: "SEPA Debit")
                    }
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.link, customDisplayLabel: "Link")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.klarna, customDisplayLabel: "Klarna")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.affirm, customDisplayLabel: "Affirm")
                    TextField("pm_type:sfu_value (comma separated)", text: additionalPaymentMethodOptionsSetupFutureUsageBinding)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }.padding()

        }
    }

    var additionalPaymentMethodOptionsSetupFutureUsageBinding: Binding<String> {
        Binding<String> {
            return viewModel.paymentMethodOptionsSetupFutureUsage.additionalPaymentMethodOptionsSetupFutureUsage ?? ""
        } set: { newString in
            viewModel.paymentMethodOptionsSetupFutureUsage.additionalPaymentMethodOptionsSetupFutureUsage = newString
        }
    }
}
