//
//  RegistrationView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import StripeCore
import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A view used to collect additional account registration information.
struct RegistrationView: View {

    /// The coordinator to use to perform registration.
    let coordinator: CryptoOnrampCoordinator

    /// The email address associated with the new account being registered.
    let email: String

    /// The OAuth scopes selected for authentication.
    let selectedScopes: [OAuthScopes]

    /// Called when registration and authentication succeed.
    let onCompleted: () -> Void

    @State private var phoneNumber: String = ""
    @State private var country: String = "US"
    @State private var errorMessage: String?
    @State private var isRegistrationComplete: Bool = false
    @State private var showUpdatePhoneNumberSheet: Bool = false
    @State private var updatePhoneNumberInput: String = ""

    @Environment(\.isLoading) private var isLoading

    @FocusState private var isPhoneNumberFieldFocused: Bool
    @FocusState private var isCountryFieldFocused: Bool

    /// Strips spaces, dashes, and parentheses from a phone number for E.164 compatibility.
    /// Sanitization is done on submit rather than on input so the field preserves readable
    /// formatting (e.g. from autofill) while the user verifies the number.
    private static func sanitizePhoneNumber(_ value: String) -> String {
        value.filter { $0.isNumber || $0 == "+" }
    }

    private var isRegisterButtonDisabled: Bool {
        isLoading.wrappedValue || phoneNumber.isEmpty
    }

    private var isUpdatePhoneNumberButtonDisabled: Bool {
        isLoading.wrappedValue || !isRegistrationComplete
    }

    private var isAuthenticateButtonDisabled: Bool {
        isLoading.wrappedValue
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

                if isRegistrationComplete {
                    Button("Authenticate") {
                        resetFocusState()
                        Task {
                            try await verify()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isAuthenticateButtonDisabled)
                    .opacity(isAuthenticateButtonDisabled ? 0.5 : 1)
                } else {
                    Button("Register") {
                        resetFocusState()
                        registerUser()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isRegisterButtonDisabled)
                    .opacity(isRegisterButtonDisabled ? 0.5 : 1)
                }

                Button("Update Phone Number") {
                    resetFocusState()
                    updatePhoneNumberInput = phoneNumber
                    showUpdatePhoneNumberSheet = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isUpdatePhoneNumberButtonDisabled)
                .opacity(isUpdatePhoneNumberButtonDisabled ? 0.5 : 1)

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

            }
            .padding()
        }
        .navigationTitle("Registration")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Update phone number", isPresented: $showUpdatePhoneNumberSheet) {
            TextField("New phone number", text: $updatePhoneNumberInput)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
            Button("Submit") {
                updatePhoneNumber(to: updatePhoneNumberInput)
            }
            Button("Cancel", role: .cancel) {
                updatePhoneNumberInput = ""
            }
        }
    }

    private func registerUser() {
        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                try await coordinator.registerLinkUser(
                    email: email,
                    fullName: nil,
                    phone: Self.sanitizePhoneNumber(phoneNumber),
                    country: country
                )

                await MainActor.run {
                    isRegistrationComplete = true
                }
                // Continue directly into authentication
                try await verify()
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    isRegistrationComplete = false
                    if let cryptoError = error as? CryptoOnrampCoordinator.Error, case .invalidPhoneFormat = cryptoError {
                        errorMessage = "Invalid phone format. Please use E.164 format (e.g., +12125551234)"
                    } else {
                        errorMessage = "Registration failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func verify() async throws {
        // Authenticate with the demo merchant backend as well.
        let response = try await APIClient.shared.createAuthIntent(oauthScopes: selectedScopes)

        await MainActor.run {
            isLoading.wrappedValue = true
            errorMessage = nil
        }

        if await presentAuthorization(laiId: response.authIntentId, using: coordinator) {
            await MainActor.run {
                isLoading.wrappedValue = false
                onCompleted()
            }
        } else {
            await MainActor.run {
                isLoading.wrappedValue = false
            }
        }
    }

    private func presentAuthorization(laiId: String, using coordinator: CryptoOnrampCoordinator) async -> Bool {
        if let viewController = UIApplication.shared.findTopNavigationController() {
            do {
                let result = try await coordinator.authorize(linkAuthIntentId: laiId, from: viewController)

                switch result {
                case let .consented(customerId):
                    try await APIClient.shared.saveUser(cryptoCustomerId: customerId)
                    return true
                case .denied:
                    await MainActor.run {
                        errorMessage = "Consent rejected"
                    }
                    return false
                case .canceled:
                    return false
                @unknown default:
                    return false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
                return false
            }
        } else {
            await MainActor.run {
                errorMessage = "Unable to find view controller to present from."
            }
            return false
        }
    }

    private func updatePhoneNumber(to phoneNumber: String) {
        isLoading.wrappedValue = true
        Task {
            do {
                let sanitized = Self.sanitizePhoneNumber(phoneNumber)
                try await coordinator.updatePhoneNumber(to: sanitized)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    updatePhoneNumberInput = ""
                    self.phoneNumber = sanitized
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Updating phone number failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func resetFocusState() {
        isPhoneNumberFieldFocused = false
        isCountryFieldFocused = false
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        RegistrationView(
            coordinator: coordinator,
            email: "test@example.com",
            selectedScopes: OAuthScopes.requiredScopes,
            onCompleted: {}
        )
    }
}
