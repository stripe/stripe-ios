//
//  RegistrationView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import StripeCore
import SwiftUI

@_spi(STP)
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

    /// Whether the app is running in livemode or testmode.
    let livemode: Bool

    /// Called when registration and authentication succeed. Provides the crypto customer id.
    let onCompleted: (_ customerId: String) -> Void

    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var country: String = "US"
    @State private var errorMessage: String?
    @State private var isRegistrationComplete: Bool = false
    @State private var showUpdatePhoneNumberSheet: Bool = false
    @State private var updatePhoneNumberInput: String = ""

    @Environment(\.isLoading) private var isLoading

    @FocusState private var isFullNameFieldFocused: Bool
    @FocusState private var isPhoneNumberFieldFocused: Bool
    @FocusState private var isCountryFieldFocused: Bool

    private var isRegisterButtonDisabled: Bool {
        isLoading.wrappedValue || phoneNumber.isEmpty
    }

    private var isUpdatePhoneNumberButtonDisabled: Bool {
        !isRegistrationComplete
    }

    private var shouldDisableButtons: Bool {
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

                if isRegistrationComplete {
                    Button("Authenticate") {
                        Task {
                            try await verify()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(shouldDisableButtons)
                    .opacity(shouldDisableButtons ? 0.5 : 1)
                } else {
                    Button("Register") {
                        registerUser()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isRegisterButtonDisabled)
                    .opacity(isRegisterButtonDisabled ? 0.5 : 1)
                }

                Button("Update Phone Number") {
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
                    fullName: fullName.isEmpty ? nil : fullName,
                    phone: phoneNumber,
                    country: country
                )

                await MainActor.run {
                    isLoading.wrappedValue = false
                    isRegistrationComplete = true
                }
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
        let response = try await APIClient.shared.authenticateUser(
            with: email,
            oauthScopes: selectedScopes,
            livemode: livemode
        )
        let laiId = response.data.id

        await MainActor.run {
            isLoading.wrappedValue = true
            errorMessage = nil
        }

        if let customerId = await presentAuthorization(laiId: laiId, using: coordinator) {
            await MainActor.run {
                isLoading.wrappedValue = false
                onCompleted(customerId)
            }
        } else {
            await MainActor.run {
                isLoading.wrappedValue = false
            }
        }
    }

    private func presentAuthorization(laiId: String, using coordinator: CryptoOnrampCoordinator) async -> String? {
        if let viewController = UIApplication.shared.findTopNavigationController() {
            do {
                let result = try await coordinator.authorize(linkAuthIntentId: laiId, from: viewController)

                switch result {
                case .consented(let customerId):
                    return customerId
                case .denied:
                    await MainActor.run {
                        errorMessage = "Consent rejected"
                    }
                    return nil
                case .canceled:
                    return nil
                @unknown default:
                    return nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
                return nil
            }
        } else {
            await MainActor.run {
                errorMessage = "Unable to find view controller to present from."
            }
            return nil
        }
    }

    private func updatePhoneNumber(to phoneNumber: String) {
        isLoading.wrappedValue = true
        Task {
            do {
                try await coordinator.updatePhoneNumber(to: phoneNumber)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    updatePhoneNumberInput = ""
                    self.phoneNumber = phoneNumber
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Updating phone number failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        RegistrationView(
            coordinator: coordinator,
            email: "test@example.com",
            selectedScopes: OAuthScopes.requiredScopes,
            livemode: false,
            onCompleted: { _ in }
        )
    }
}
