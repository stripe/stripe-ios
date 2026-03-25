//
//  KYCInfoView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/7/25.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A view used to collect KYC (Know Your Customer) data and exercise the `CryptoOnrampCoordinator's` `attachKYCInfo(info:)` functionality.
struct KYCInfoView: View {

    /// Controls which KYC information set this form collects.
    enum CollectionMode: Equatable {

        /// Original behavior where all fields are shown and date of birth + id number are required.
        case original

        /// Level 0 collection where name/address fields are required and date of birth + id number are optional.
        case kycLevel0

        /// Level 1 step-up collection where required level 0 fields are already collected,
        /// so only date of birth + id number are collected and required.
        case kycLevel1StepUp

        fileprivate var requiresLevel0Fields: Bool {
            switch self {
            case .original, .kycLevel0:
                return true
            case .kycLevel1StepUp:
                return false
            }
        }

        fileprivate var requiresDateOfBirthAndIdNumber: Bool {
            switch self {
            case .original, .kycLevel1StepUp:
                return true
            case .kycLevel0:
                return false
            }
        }
    }

    /// The coordinator to use to submit KYC information.
    let coordinator: CryptoOnrampCoordinator

    /// Closure called when KYC submission succeeds with the level collected by this view.
    let onCompleted: (KYCLevel) -> Void

    /// Controls which variant of KYC data collection this form performs.
    let collectionMode: CollectionMode

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var idNumber: String = ""
    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = "US"
    @State private var dateOfBirth: Date?
    @State private var errorMessage: String?

    @Environment(\.isLoading) private var isLoading

    private static let today = Date()

    @FocusState private var focusedField: Field?

    private enum Field {
        case firstName, lastName, idNumber, addressLine1, addressLine2, city, state, postalCode, country
    }

    init(
        coordinator: CryptoOnrampCoordinator,
        collectionMode: CollectionMode = .original,
        onCompleted: @escaping (KYCLevel) -> Void
    ) {
        self.coordinator = coordinator
        self.onCompleted = onCompleted
        self.collectionMode = collectionMode
        _dateOfBirth = State(initialValue: collectionMode.requiresDateOfBirthAndIdNumber ? Self.today : nil)
    }

    private var isSubmitButtonDisabled: Bool {
        if isLoading.wrappedValue {
            return true
        }

        if collectionMode.requiresLevel0Fields {
            return firstName.isEmpty
                || lastName.isEmpty
                || addressLine1.isEmpty
                || city.isEmpty
                || state.isEmpty
                || postalCode.isEmpty
                || country.isEmpty
                || (collectionMode.requiresDateOfBirthAndIdNumber && (idNumber.isEmpty || dateOfBirth == nil))
        } else {
            return idNumber.isEmpty || dateOfBirth == nil
        }
    }

    private var dateOfBirthBinding: Binding<Date> {
        Binding(
            get: { dateOfBirth ?? Self.today },
            set: { dateOfBirth = $0 }
        )
    }

    private var collectedKYCLevel: KYCLevel {
        switch collectionMode {
        case .original, .kycLevel1StepUp:
            return .level1
        case .kycLevel0:
            return .level0
        }
    }

    private func title(_ label: LocalizedStringKey, required: Bool) -> Text {
        if required {
            Text(label)
        } else {
            Text(label)
            + Text(" ")
            + Text("(optional)")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    switch collectionMode {
                    case .original, .kycLevel0:
                        Text("Please provide additional information to continue.")
                    case .kycLevel1StepUp:
                        Text("We need a bit more information before you can complete checkout.")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                if collectionMode.requiresLevel0Fields {
                    FormField(title("First Name", required: true)) {
                        makeTextField(
                            "Enter your first name",
                            text: $firstName,
                            field: .firstName,
                            autocapitalization: .words,
                            textContentType: .givenName
                        )
                    }

                    FormField(title("Last Name", required: true)) {
                        makeTextField(
                            "Enter your last name",
                            text: $lastName,
                            field: .lastName,
                            autocapitalization: .words,
                            textContentType: .familyName
                        )
                    }
                }

                if collectionMode != .kycLevel0 {
                    FormField(title("Social Security Number", required: collectionMode.requiresDateOfBirthAndIdNumber)) {
                        makeTextField(
                            "Enter your SSN",
                            text: $idNumber,
                            field: .idNumber,
                            keyboardType: .numberPad
                        )
                    }

                    FormField(title("Date of Birth", required: collectionMode.requiresDateOfBirthAndIdNumber)) {
                        DatePicker("", selection: dateOfBirthBinding, in: ...Self.today, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                }

                if collectionMode.requiresLevel0Fields {
                    FormField(title("Address Line 1", required: true)) {
                        makeTextField(
                            "Enter your street address",
                            text: $addressLine1,
                            field: .addressLine1,
                            autocapitalization: .words,
                            textContentType: .streetAddressLine1
                        )
                    }

                    FormField(title("Address Line 2", required: false)) {
                        makeTextField(
                            "Apartment, suite, etc.",
                            text: $addressLine2,
                            field: .addressLine2,
                            autocapitalization: .words,
                            textContentType: .streetAddressLine2
                        )
                    }

                    FormField(title("City", required: true)) {
                        makeTextField(
                            "Enter your city",
                            text: $city,
                            field: .city,
                            autocapitalization: .words,
                            textContentType: .addressCity
                        )
                    }

                    FormField(title("State/Province", required: true)) {
                        makeTextField(
                            "Enter your state or province",
                            text: $state,
                            field: .state,
                            autocapitalization: .words
                        )
                    }

                    FormField(title("Postal Code", required: true)) {
                        makeTextField(
                            "Enter your postal code",
                            text: $postalCode,
                            field: .postalCode,
                            textContentType: .postalCode
                        )
                    }

                    FormField(title("Country", required: true)) {
                        makeTextField(
                            "Country code",
                            text: $country,
                            field: .country,
                            autocapitalization: .allCharacters
                        )
                    }
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
            .padding()
        }
        .navigationTitle("KYC Information")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submitKYCInfo() {
        isLoading.wrappedValue = true
        errorMessage = nil

        let address: Address? = {
            if collectionMode.requiresLevel0Fields {
                Address(
                    city: city.isEmpty ? nil : city,
                    country: country.isEmpty ? nil : country,
                    line1: addressLine1.isEmpty ? nil : addressLine1,
                    line2: addressLine2.isEmpty ? nil : addressLine2,
                    postalCode: postalCode,
                    state: state
                )
            } else {
                nil
            }
        }()

        let dateOfBirth = dateOfBirth.map { dateOfBirth in
            let dateOfBirthComponents = Calendar.current.dateComponents([.day, .month, .year], from: dateOfBirth)
            return KycInfo.DateOfBirth(
                day: dateOfBirthComponents.day ?? 0,
                month: dateOfBirthComponents.month ?? 0,
                year: dateOfBirthComponents.year ?? 0
            )
        }

        let kycInfo = KycInfo(
            firstName: collectionMode.requiresLevel0Fields ? firstName : nil,
            lastName: collectionMode.requiresLevel0Fields ? lastName : nil,
            idNumber: idNumber.isEmpty ? nil : idNumber,
            address: address,
            dateOfBirth: dateOfBirth
        )

        Task {
            do {
                try await coordinator.attachKYCInfo(info: kycInfo)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    onCompleted(collectedKYCLevel)
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
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil
    ) -> some View {
        TextField(titleKey, text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .textContentType(textContentType)
            .autocapitalization(autocapitalization)
            .keyboardType(keyboardType)
            .focused($focusedField, equals: field)
    }
}

#Preview("Original") {
    PreviewWrapperView { coordinator in
        KYCInfoView(coordinator: coordinator, collectionMode: .original) { _ in }
    }
}

#Preview("Level 0") {
    PreviewWrapperView { coordinator in
        KYCInfoView(coordinator: coordinator, collectionMode: .kycLevel0) { _ in }
    }
}

#Preview("Level 1 Step Up") {
    PreviewWrapperView { coordinator in
        KYCInfoView(coordinator: coordinator, collectionMode: .kycLevel1StepUp) { _ in }
    }
}
