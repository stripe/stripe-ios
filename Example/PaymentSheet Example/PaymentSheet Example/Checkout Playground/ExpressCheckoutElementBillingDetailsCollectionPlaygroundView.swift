//
//  ExpressCheckoutElementBillingDetailsCollectionPlaygroundView.swift
//  PaymentSheet Example
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct ExpressCheckoutElementBillingDetailsCollectionPlaygroundView: View {
    @State var configuration: ExpressCheckoutElement.BillingDetailsCollectionConfiguration
    var doneAction: ((ExpressCheckoutElement.BillingDetailsCollectionConfiguration) -> Void)

    var body: some View {
        NavigationView {
            List {
                fieldsSection
                resetSection
            }
            .navigationTitle("Billing Details Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        doneAction(configuration)
                    }
                }
            }
        }
    }

    // MARK: - Fields

    @ViewBuilder
    private var fieldsSection: some View {
        Section("Fields") {
            Picker(selection: $configuration.name) {
                ForEach(ExpressCheckoutElement.BillingDetailsCollectionConfiguration.CollectionMode.allCases) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            } label: {
                Label("Name", systemImage: "person.fill")
            }
            Picker(selection: $configuration.address) {
                ForEach(ExpressCheckoutElement.BillingDetailsCollectionConfiguration.AddressCollectionMode.allCases) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            } label: {
                Label("Address", systemImage: "house.fill")
            }
        }
    }

    // MARK: - Reset

    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button("Reset to Defaults") {
                withAnimation {
                    configuration = ExpressCheckoutElement.BillingDetailsCollectionConfiguration()
                }
            }
            .foregroundColor(.red)
        }
    }
}
