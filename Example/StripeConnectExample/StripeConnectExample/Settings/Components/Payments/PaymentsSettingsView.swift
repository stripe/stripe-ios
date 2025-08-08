//
//  PaymentsSettingsView.swift
//  StripeConnect Example
//
//  Created by Torrance Yang on 8/7/25.
//

@_spi(DashboardOnly) import StripeConnect
import SwiftUI

struct PaymentsSettingsView: View {

    @Environment(\.dismiss) var dismiss
    @Binding var paymentsSettings: PaymentsSettings

    var saveEnabled: Bool {
        AppSettings.shared.paymentsSettings != paymentsSettings
    }

    var body: some View {
        List {
            // Amount Filter Section
            Section("Amount Filter") {
                Picker("Amount Filter Type", selection: $paymentsSettings.amountFilterType) {
                    ForEach(PaymentsSettings.AmountFilterType.allCases) { filterType in
                        Text(filterType.displayLabel)
                            .tag(filterType)
                    }
                }

                switch paymentsSettings.amountFilterType {
                case .none:
                    EmptyView()
                case .equals, .greaterThan, .lessThan:
                    TextField("Amount (dollars)", text: $paymentsSettings.amountValue)
                        .keyboardType(.decimalPad)
                case .between:
                    TextField("Lower bound (dollars)", text: $paymentsSettings.amountLowerBound)
                        .keyboardType(.decimalPad)
                    TextField("Upper bound (dollars)", text: $paymentsSettings.amountUpperBound)
                        .keyboardType(.decimalPad)
                }
            }

            // Date Filter Section
            Section("Date Filter") {
                Picker("Date Filter Type", selection: $paymentsSettings.dateFilterType) {
                    ForEach(PaymentsSettings.DateFilterType.allCases) { filterType in
                        Text(filterType.displayLabel)
                            .tag(filterType)
                    }
                }

                switch paymentsSettings.dateFilterType {
                case .none:
                    EmptyView()
                case .before:
                    DatePicker("Before Date", selection: $paymentsSettings.beforeDate, displayedComponents: .date)
                case .after:
                    DatePicker("After Date", selection: $paymentsSettings.afterDate, displayedComponents: .date)
                case .between:
                    DatePicker("Start Date", selection: $paymentsSettings.startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $paymentsSettings.endDate, displayedComponents: .date)
                }
            }

            // Status Filter Section
            Section("Status Filter") {
                ForEach(PaymentsSettings.availableStatusStrings, id: \.self) { statusString in
                    HStack {
                        Text(PaymentsSettings.statusDisplayName(statusString))
                        Spacer()
                        if paymentsSettings.selectedStatuses.contains(statusString) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if paymentsSettings.selectedStatuses.contains(statusString) {
                            paymentsSettings.selectedStatuses.remove(statusString)
                        } else {
                            paymentsSettings.selectedStatuses.insert(statusString)
                        }
                    }
                }
            }

            // Payment Method Filter Section
            Section("Payment Method Filter") {
                Picker("Payment Method", selection: $paymentsSettings.selectedPaymentMethod) {
                    Text("None").tag(Optional<String>.none)
                    ForEach(PaymentsSettings.availablePaymentMethodStrings, id: \.self) { methodString in
                        Text(PaymentsSettings.paymentMethodDisplayName(methodString))
                            .tag(Optional(methodString))
                    }
                }
            }

            // Reset Section
            Section {
                Button {
                    paymentsSettings = PaymentsSettings()
                    AppSettings.shared.paymentsSettings = paymentsSettings
                } label: {
                    Text("Reset to defaults")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Payments Filter Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    AppSettings.shared.paymentsSettings = paymentsSettings
                    dismiss()
                } label: {
                    Text("Save")
                }
                .disabled(!saveEnabled)
            }
        }
        .environment(\.horizontalSizeClass, .compact)
    }
}
