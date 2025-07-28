//
//  RegistrationView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import SwiftUI
import StripeCore

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

struct RegistrationView: View {
    let coordinator: CryptoOnrampCoordinator
    let email: String

    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var country: String = "US"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    @FocusState private var isFullNameFieldFocused: Bool
    @FocusState private var isPhoneNumberFieldFocused: Bool
    @FocusState private var isCountryFieldFocused: Bool

    private var isRegisterButtonDisabled: Bool {
        isLoading || phoneNumber.isEmpty || phoneNumber.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Finish setting up your new account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                    Text(email)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name (optional)")
                        .font(.headline)
                    TextField("Enter your full name", text: $fullName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .focused($isFullNameFieldFocused)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.headline)
                    TextField("Enter phone number (e.g., +12125551234)", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .focused($isPhoneNumberFieldFocused)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Country")
                        .font(.headline)
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
            }
            .padding()
        }
        .navigationTitle("Registration")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            ZStack {
                if isLoading {
                    ProgressView("Registering…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        )
    }

    private func registerUser() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let customerId = try await coordinator.registerLinkUser(
                    fullName: fullName.isEmpty ? nil : fullName,
                    phone: phoneNumber,
                    country: country
                )

                await MainActor.run {
                    isLoading = false
                    // TODO: Navigate to next step or show success
                    print("Registration successful! Customer ID: \(customerId)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
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

private struct RegistrationPreviewView: View {
    @State var coordinator: CryptoOnrampCoordinator?
    var body: some View {
        NavigationView {
            if let coordinator = coordinator {
                RegistrationView(coordinator: coordinator, email: "test@example.com")
            }
        }
        .onAppear {
            STPAPIClient.shared.setUpPublishableKey()
            Task {
                let coordinator = try? await CryptoOnrampCoordinator.create(appearance: .init())

                await MainActor.run {
                    self.coordinator = coordinator
                }
            }
        }
    }
}

#Preview {
    RegistrationPreviewView()
}
