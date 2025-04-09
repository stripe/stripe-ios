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
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.link, disabledSettings: [.on_session], customDisplayLabel: "Link")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.amazonPay, disabledSettings: [.on_session], customDisplayLabel: "Amazon Pay")
                    SettingPickerView(setting: $viewModel.paymentMethodOptionsSetupFutureUsage.affirm, disabledSettings: [.off_session, .on_session], customDisplayLabel: "Affirm")
                }
            }.padding()

        }
    }
}
