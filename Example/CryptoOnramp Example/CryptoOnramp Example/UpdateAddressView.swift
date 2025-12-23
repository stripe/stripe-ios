//
//  UpdateAddressView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 11/3/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCryptoOnramp

import SwiftUI

/// A view that allows the user to enter a new address.
struct UpdateAddressView: View {

    /// A closure called when the user confirms their address.
    let onConfirm: (Address) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = "US"

    @FocusState private var focusedField: Field?

    private enum Field {
        case addressLine1, addressLine2, city, state, postalCode, country
    }

    private var isSubmitButtonDisabled: Bool {
        addressLine1.isEmpty || city.isEmpty || country.isEmpty
    }

    // MARK: - View

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    FormField("Address Line 1") {
                        makeTextField(
                            "Enter your street address",
                            text: $addressLine1,
                            field: .addressLine1,
                            autocapitalization: .words
                        )
                    }

                    FormField("Address Line 2 (optional)") {
                        makeTextField(
                            "Apartment, suite, etc.",
                            text: $addressLine2,
                            field: .addressLine2,
                            autocapitalization: .words
                        )
                    }

                    FormField("City") {
                        makeTextField(
                            "Enter your city",
                            text: $city,
                            field: .city,
                            autocapitalization: .words
                        )
                    }

                    FormField("State/Province") {
                        makeTextField(
                            "Enter your state or province",
                            text: $state,
                            field: .state,
                            autocapitalization: .words
                        )
                    }

                    FormField("Postal Code") {
                        makeTextField(
                            "Enter your postal code",
                            text: $postalCode,
                            field: .postalCode
                        )
                    }

                    FormField("Country") {
                        makeTextField(
                            "Country code",
                            text: $country,
                            field: .country,
                            autocapitalization: .allCharacters
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Update Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        focusedField = nil
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        focusedField = nil
                        dismiss()
                        onConfirm(
                            Address(
                                city: stringIfHasContentsElseNil(
                                    city.trimmingCharacters(in: .whitespacesAndNewlines)
                                ),
                                country: stringIfHasContentsElseNil(
                                    country.trimmingCharacters(in: .whitespacesAndNewlines)
                                ),
                                line1: stringIfHasContentsElseNil(
                                    addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
                                ),
                                line2: stringIfHasContentsElseNil(
                                    addressLine2.trimmingCharacters(in: .whitespacesAndNewlines)
                                ),
                                postalCode: stringIfHasContentsElseNil(
                                    postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
                                ),
                                state: stringIfHasContentsElseNil(
                                    state.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                            )
                        )
                    }
                    .disabled(isSubmitButtonDisabled)
                    .opacity(isSubmitButtonDisabled ? 0.5 : 1)
                }
            }
        }
    }

    private func makeTextField(
        _ titleKey: LocalizedStringKey,
        text: Binding<String>,
        field: Field,
        autocapitalization: UITextAutocapitalizationType = .none
    ) -> some View {
        TextField(titleKey, text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(autocapitalization)
            .focused($focusedField, equals: field)
    }
}

#Preview {
    UpdateAddressView { _ in }
}
