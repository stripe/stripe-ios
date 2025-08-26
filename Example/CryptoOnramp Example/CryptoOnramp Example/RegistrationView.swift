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

    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var country: String = "US"
    @State private var errorMessage: String?
    @State private var showAuthenticatedView: Bool = false
    @State private var registrationCustomerId: String?
    @State private var isRegistrationComplete: Bool = false

    @Environment(\.isLoading) private var isLoading

    @FocusState private var isFullNameFieldFocused: Bool
    @FocusState private var isPhoneNumberFieldFocused: Bool
    @FocusState private var isCountryFieldFocused: Bool

    private var isRegisterButtonDisabled: Bool {
        isLoading.wrappedValue || phoneNumber.isEmpty
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
                    Button("Retry Verification") {
                        Task {
                            await verify()
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
                try await coordinator.registerLinkUser(
                    email: email,
                    fullName: fullName.isEmpty ? nil : fullName,
                    phone: phoneNumber,
                    country: country
                )

                // Authenticate with the demo merchant backend as well.
                _ = try await APIClient.shared.authenticateUser(
                    with: email,
                    oauthScopes: selectedScopes
                )

                await verify()
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

    private func presentVerification(using coordinator: CryptoOnrampCoordinator) async -> String? {
        if let viewController = UIApplication.shared.findTopNavigationController() {
            do {
                let result = try await coordinator.authenticateUser(from: viewController)

                switch result {
                case .completed(let customerId):
                    return customerId
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

    private func verify() async {
        await MainActor.run {
            isLoading.wrappedValue = true
            errorMessage = nil
        }

        if let customerId = await presentVerification(using: coordinator) {
            await MainActor.run {
                isLoading.wrappedValue = false
                isRegistrationComplete = true
                self.registrationCustomerId = customerId

                // Delay so the navigation link animation doesn't get canceled.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showAuthenticatedView = true
                }
            }
        } else {
            await MainActor.run {
                isLoading.wrappedValue = false
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        RegistrationView(
            coordinator: coordinator,
            email: "test@example.com",
            selectedScopes: OAuthScopes.onrampScope
        )
    }
}
