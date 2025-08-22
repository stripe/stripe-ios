//
//  KYCInfoView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/7/25.
//

import SwiftUI

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A view used to collect KYC (Know Your Customer) data and exercise the `CryptoOnrampCoordinator's` `attachKYCInfo(info:)` functionality.
struct KYCInfoView: View {

    /// The coordinator to use to submit KYC information.
    let coordinator: CryptoOnrampCoordinator

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var idNumber: String = ""
    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = "US"
    @State private var dateOfBirth: Date = Self.today
    @State private var errorMessage: String?
    @State private var isKYCComplete = false

    @Environment(\.isLoading) private var isLoading

    private static let today = Date()

    @FocusState private var focusedField: Field?

    private enum Field {
        case firstName, lastName, idNumber, addressLine1, addressLine2, city, state, postalCode, country
    }

    private var isSubmitButtonDisabled: Bool {
        isLoading.wrappedValue || firstName.isEmpty || lastName.isEmpty || idNumber.isEmpty || addressLine1.isEmpty || city.isEmpty || country.isEmpty
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isKYCComplete {
                    Text("KYC Information Submitted")
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(.green.opacity(0.1))
                        }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Please provide additional information to continue.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    FormField("First Name") {
                        makeTextField(
                            "Enter your first name",
                            text: $firstName,
                            field: .firstName,
                            autocapitalization: .words
                        )
                    }

                    FormField("Last Name") {
                        makeTextField(
                            "Enter your last name",
                            text: $lastName,
                            field: .lastName,
                            autocapitalization: .words
                        )
                    }

                    FormField("Social Security Number") {
                        makeTextField(
                            "Enter your SSN",
                            text: $idNumber,
                            field: .idNumber,
                            keyboardType: .numberPad
                        )
                    }

                    FormField("Date of Birth") {
                        DatePicker("", selection: $dateOfBirth, in: ...Self.today, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }

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

                    if let errorMessage {
                        ErrorMessageView(message: errorMessage)
                    }

                    Button("Submit") {
                        focusedField = nil
                        submitKYCInfo()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isSubmitButtonDisabled)
                    .opacity(isSubmitButtonDisabled ? 0.5 : 1)
                }
            }
            .padding()
        }
        .navigationTitle("KYC Information")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submitKYCInfo() {
        isLoading.wrappedValue = true
        errorMessage = nil

        let address = Address(
            city: city.isEmpty ? nil : city,
            country: country.isEmpty ? nil : country,
            line1: addressLine1.isEmpty ? nil : addressLine1,
            line2: addressLine2.isEmpty ? nil : addressLine2,
            postalCode: postalCode.isEmpty ? nil : postalCode,
            state: state.isEmpty ? nil : state
        )

        let dateOfBirthComponents = Calendar.current.dateComponents([.day, .month, .year], from: dateOfBirth)

        let dateOfBirth = KycInfo.DateOfBirth(
            day: dateOfBirthComponents.day ?? 0,
            month: dateOfBirthComponents.month ?? 0,
            year: dateOfBirthComponents.year ?? 0
        )

        let kycInfo = KycInfo(
            firstName: firstName,
            lastName: lastName,
            idNumber: idNumber,
            address: address,
            dateOfBirth: dateOfBirth
        )

        Task {
            do {
                try await coordinator.attachKYCInfo(info: kycInfo)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    isKYCComplete = true
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "KYC information submission failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func makeTextField(
        _ titleKey: LocalizedStringKey,
        text: Binding<String>,
        field: Field,
        autocapitalization: UITextAutocapitalizationType = .none,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        TextField(titleKey, text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(autocapitalization)
            .keyboardType(keyboardType)
            .focused($focusedField, equals: field)
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        KYCInfoView(coordinator: coordinator)
    }
}
