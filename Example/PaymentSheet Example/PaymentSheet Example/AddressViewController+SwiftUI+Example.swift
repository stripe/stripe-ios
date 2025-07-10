//
//  AddressViewController+SwiftUI+Example.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/7/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import SwiftUI
import StripePaymentSheet
@_spi(STP) import StripeCore

@available(iOS 15.0, *)
public struct AddressCollectionExampleView: View {
    @State private var showingAddressSheet = false
    @State private var collectedAddress: AddressViewController.AddressDetails?
    
    private var configuration: AddressViewController.Configuration {
        STPAPIClient.shared.publishableKey = "pk_test"
        
        var config = AddressViewController.Configuration()
        config.allowedCountries = ["US", "CA", "GB", "AU"]
        config.buttonTitle = "Save Address"
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
                        configuration: configuration
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
        AddressCollectionExampleView()
    }
}
