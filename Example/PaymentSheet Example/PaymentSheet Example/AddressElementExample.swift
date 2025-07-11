//
//  AddressViewController+SwiftUI+Example.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/7/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
public struct AddressElementExampleView: View {
    @State private var showingAddressSheet = false
    @State private var collectedAddress: AddressElement.AddressDetails?

    private func makeConfiguration() -> AddressElement.Configuration {
        STPAPIClient.shared.publishableKey = "pk_test"

        var config = AddressElement.Configuration()
        config.allowedCountries = ["US", "CA", "GB", "AU"]
        config.buttonTitle = "Save Address"

        // Pre-populate with existing address if available
        if let address = collectedAddress {
            config.defaultValues.name = address.name
            config.defaultValues.address.line1 = address.address.line1
            config.defaultValues.address.line2 = address.address.line2
            config.defaultValues.address.city = address.address.city
            config.defaultValues.address.state = address.address.state
            config.defaultValues.address.postalCode = address.address.postalCode
            config.defaultValues.address.country = address.address.country
        }

        return config
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Example: Using .sheet with isPresented
                Button("Collect Address") {
                    showingAddressSheet = true
                }
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $showingAddressSheet) {
                    AddressElement(
                        address: $collectedAddress,
                        configuration: makeConfiguration()
                    )
                }

                // Display collected address
                if let address = collectedAddress {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collected Address:")
                            .font(.headline)

                        Text("Name: \(address.name ?? "Not provided")")

                        if !address.address.line1.isEmpty {
                            Text("Address: \(address.address.line1)")
                        }

                        if let city = address.address.city, !city.isEmpty {
                            Text("City: \(city)")
                        }

                        if let state = address.address.state, !state.isEmpty {
                            Text("State: \(state)")
                        }

                        if let postalCode = address.address.postalCode, !postalCode.isEmpty {
                            Text("ZIP: \(postalCode)")
                        }

                        if !address.address.country.isEmpty {
                            Text("Country: \(address.address.country)")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("AddressElement SwiftUI Example")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

@available(iOS 15.0, *)
struct AddressCollectionExampleView_Previews: PreviewProvider {
    static var previews: some View {
        AddressElementExampleView()
    }
}
