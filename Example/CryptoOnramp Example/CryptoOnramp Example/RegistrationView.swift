//
//  RegistrationView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import StripeCore
import SwiftUI

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A view used to collect additional account registration information.
struct RegistrationView: View {

    /// The coordinator to use to perform registration.
    let coordinator: CryptoOnrampCoordinator

    /// The email address associated with the new account being registered.
    let email: String

    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var country: String = "US"
    @State private var errorMessage: String?
    @State private var showAuthenticatedView: Bool = false
    @State private var registrationCustomerId: String?

    @Environment(\.isLoading) private var isLoading

    @FocusState private var isFullNameFieldFocused: Bool
    @FocusState private var isPhoneNumberFieldFocused: Bool
    @FocusState private var isCountryFieldFocused: Bool

    private var isRegisterButtonDisabled: Bool {
        isLoading.wrappedValue || phoneNumber.isEmpty
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Finish setting up your new account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                FormField("Email") {
                    Text(email)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.secondary)
                }

                FormField("Full Name (optional)") {
                    TextField("Enter your full name", text: $fullName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .focused($isFullNameFieldFocused)
                }

                FormField("Phone Number") {
                    TextField("Enter phone number (e.g., +12125551234)", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .focused($isPhoneNumberFieldFocused)
                }

                FormField("Country") {
                    TextField("Country code", text: $country)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .focused($isCountryFieldFocused)
                }

                Button("Register") {
                    registerUser()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isRegisterButtonDisabled)
                .opacity(isRegisterButtonDisabled ? 0.5 : 1)

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                if let customerId = registrationCustomerId {
                    HiddenNavigationLink(
                        destination: AuthenticatedView(coordinator: coordinator, customerId: customerId),
                        isActive: $showAuthenticatedView
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Registration")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func registerUser() {
        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                let customerId = try await coordinator.registerLinkUser(
                    fullName: fullName.isEmpty ? nil : fullName,
                    phone: phoneNumber,
                    country: country
                )

                await MainActor.run {
                    isLoading.wrappedValue = false
                    registrationCustomerId = customerId

                    // Delay so the navigation link animation doesn’t get canceled.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAuthenticatedView = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    if let cryptoError = error as? CryptoOnrampCoordinator.Error {
                        switch cryptoError {
                        case .invalidPhoneFormat:
                            errorMessage = "Invalid phone format. Please use E.164 format (e.g., +12125551234)"
                        @unknown default:
                            errorMessage = "An unknown error occurred. Please try again later."
                        }
                    } else {
                        errorMessage = "Registration failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        RegistrationView(
            coordinator: coordinator,
            email: "test@example.com"
        )
    }
}
