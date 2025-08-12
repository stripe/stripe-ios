//
//  CryptoOnrampExampleView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/24/25.
//

import StripeCore
import SwiftUI

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// The main content view of the example CryptoOnramp app.
struct CryptoOnrampExampleView: View {
    @State private var coordinator: CryptoOnrampCoordinator?
    @State private var errorMessage: String?
    @State private var email: String = ""
    @State private var showRegistration: Bool = false
    @State private var showAuthenticatedView: Bool = false
    @State private var authenticationCustomerId: String?

    @Environment(\.isLoading) private var isLoading
    @FocusState private var isEmailFieldFocused: Bool

    private var isNextButtonDisabled: Bool {
        isLoading.wrappedValue || email.isEmpty || coordinator == nil
    }

    // MARK: - View

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    FormField("Email") {
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
                        isEmailFieldFocused = false
                        lookupConsumerAndContinue()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isNextButtonDisabled)
                    .opacity(isNextButtonDisabled ? 0.5 : 1)

                    if let errorMessage {
                        ErrorMessageView(message: errorMessage)
                    }

                    if let coordinator {
                        HiddenNavigationLink(
                            destination: RegistrationView(coordinator: coordinator, email: email),
                            isActive: $showRegistration
                        )

                        if let customerId = authenticationCustomerId {
                            HiddenNavigationLink(
                                destination: AuthenticatedView(
                                    coordinator: coordinator,
                                    customerId: customerId
                                ),
                                isActive: $showAuthenticatedView
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("CryptoOnramp Example")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            guard coordinator == nil else {
                return
            }
            initializeCoordinator()
        }
    }

    private func initializeCoordinator() {
        STPAPIClient.shared.setUpPublishableKey()

        isLoading.wrappedValue = true
        Task {
            do {
                let appearance = LinkAppearance(
                    colors: .init(primary: .systemPurple, selectedBorder: .separator),
                    primaryButton: .init(cornerRadius: 32, height: 80),
                    style: .automatic
                )
                let coordinator = try await CryptoOnrampCoordinator.create(appearance: appearance)

                await MainActor.run {
                    self.coordinator = coordinator
                    self.isLoading.wrappedValue = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading.wrappedValue = false
                    self.errorMessage = "Failed to initialize CryptoOnrampCoordinator: \(error.localizedDescription)"
                }
            }
        }
    }

    private func lookupConsumerAndContinue() {
        guard let coordinator else { return }
        isLoading.wrappedValue = true
        Task {
            do {
                let lookupResult = try await coordinator.lookupConsumer(with: email)
                await MainActor.run {
                    errorMessage = nil
                    isLoading.wrappedValue = false

                    if lookupResult {
                        presentVerification(using: coordinator)
                    } else {
                        showRegistration = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Customer lookup failed. Ensure the email address is properly formatted. (Underlying error: \(error.localizedDescription))"
                }
            }
        }
    }

    private func presentVerification(using coordinator: CryptoOnrampCoordinator) {
        if let viewController = UIApplication.shared.findTopNavigationController() {
            Task {
                do {
                    let result = try await coordinator.presentForVerification(from: viewController)
                    switch result {
                    case .completed(customerId: let customerId):
                        await MainActor.run {
                            authenticationCustomerId = customerId

                            // Delay so the navigation link animation doesn’t get canceled.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showAuthenticatedView = true
                            }
                        }
                    case .canceled:
                        // do nothing, verification canceled.
                        break
                    @unknown default:
                        // do nothing, verification canceled.
                        break
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            errorMessage = "Unable to find view controller to present from."
        }
    }
}

#Preview {
    CryptoOnrampExampleView()
}
