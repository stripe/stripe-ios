//
//  CustomerSheetCustomerSessionPlaygroundView.swift
//  PaymentSheet Example

import StripePaymentSheet
import SwiftUI

struct CustomerSheetCustomerSessionPlaygroundView: View {
    @State var viewModel: CustomerSheetTestPlaygroundSettings
    var doneAction: ((CustomerSheetTestPlaygroundSettings) -> Void) = { _ in }

    var body: some View {
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
                    SettingPickerView(setting: $viewModel.paymentMethodRemove)
                    SettingPickerView(setting: $viewModel.paymentMethodRemoveLast)
                    SettingPickerView(setting: $viewModel.paymentMethodAllowRedisplayFilters)
                    SettingPickerView(setting: $viewModel.paymentMethodSyncDefault)
                }
            }.padding()

        }
    }
}
