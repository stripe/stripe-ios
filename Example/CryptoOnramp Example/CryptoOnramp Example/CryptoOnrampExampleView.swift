//
//  CryptoOnrampExampleView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/24/25.
//

import SwiftUI
import StripeCore

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

struct CryptoOnrampExampleView: View {
    @State private var coordinator: CryptoOnrampCoordinator?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = true
    @State private var email: String = ""
    @State private var showRegistration: Bool = false

    @FocusState private var isEmailFieldFocused: Bool

    private var isNextButtonDisabled: Bool {
        isLoading || email.isEmpty || coordinator == nil
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        TextField("Enter email address", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($isEmailFieldFocused)
                            .submitLabel(.go)
                            .onSubmit {
                                if !isNextButtonDisabled {
                                    lookupConsumerAndContinue()
                                }
                            }
                    }

                    Button("Next") {
                        lookupConsumerAndContinue()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isNextButtonDisabled)
                    .opacity(isNextButtonDisabled ? 0.5 : 1)

                    if let errorMessage {
                        ErrorMessageView(message: errorMessage)
                    }

                    if let coordinator {
                        NavigationLink(
                            destination: RegistrationView(coordinator: coordinator, email: email),
                            isActive: $showRegistration
                        ) { EmptyView() }
                            .opacity(0)
                            .frame(width: 0, height: 0)
                    }
                }
                .padding()
            }
            .navigationTitle("CryptoOnramp Example")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            initializeCoordinator()
        }
        .overlay(
            ZStack {
                if isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        )
    }

    private func initializeCoordinator() {
        STPAPIClient.shared.setUpPublishableKey()

        Task {
            do {
                let coordinator = try await CryptoOnrampCoordinator.create(appearance: .init())

                await MainActor.run {
                    self.coordinator = coordinator
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to initialize CryptoOnrampCoordinator: \(error.localizedDescription)"
                }
            }
        }
    }

    private func lookupConsumerAndContinue() {
        guard let coordinator else { return }
        isLoading = true
        Task {
            do {
                let lookupResult = try await coordinator.lookupConsumer(with: email)
                await MainActor.run {
                    errorMessage = nil
                    isLoading = false

                    if lookupResult {
                        // show verification
                    } else {
                        showRegistration = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Customer lookup failed. Ensure the email address is properly formatted. (Underlying error: \(error.localizedDescription))"
                }
            }
        }

    }
}

#Preview {
    CryptoOnrampExampleView()
}
