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
    @State private var selectedScopes: Set<OAuthScopes> = Set(OAuthScopes.inlineScope)
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

                    OAuthScopeSelector(
                        selectedScopes: $selectedScopes,
                        onInlineScopesSelected: {
                            selectedScopes = Set(OAuthScopes.inlineScope)
                        },
                        onAllScopesSelected: {
                            selectedScopes = Set(OAuthScopes.allScopes)
                        }
                    )

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
                            destination: RegistrationView(
                                coordinator: coordinator,
                                email: email,
                                selectedScopes: Array(selectedScopes)
                            ),
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
        .navigationViewStyle(.stack)
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
                let lavenderColor = UIColor(
                    red: 171/255.0,
                    green: 159/255.0,
                    blue: 242/255.0,
                    alpha: 1.0
                )
                let appearance = LinkAppearance(
                    colors: .init(primary: lavenderColor, selectedBorder: .label),
                    primaryButton: .init(cornerRadius: 16, height: 56),
                    style: .automatic,
                    reduceLinkBranding: true
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
                let lookupResult = try await coordinator.hasLinkAccount(with: email)
                if lookupResult {
                    // Authenticate with the demo merchant backend as well.
                    let laiId = try await APIClient.shared.authenticateUser(
                        with: email,
                        oauthScopes: Array(selectedScopes)
                    ).data.id
                    print( "Successfully authenticated user with demo backend. Id: \(laiId)")
                }
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
                    let result = try await coordinator.authenticateUser(from: viewController)
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

struct OAuthScopeSelector: View {
    @Binding var selectedScopes: Set<OAuthScopes>
    let onInlineScopesSelected: () -> Void
    let onAllScopesSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("OAuth Scopes")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 8) {
                    Button("Inline") {
                        onInlineScopesSelected()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("All") {
                        onAllScopesSelected()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            LazyVGrid(columns: [GridItem()], spacing: 8) {
                ForEach(OAuthScopes.allCases, id: \.self) { scope in
                    Button(action: {
                        if selectedScopes.contains(scope) {
                            selectedScopes.remove(scope)
                        } else {
                            selectedScopes.insert(scope)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: selectedScopes.contains(scope) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedScopes.contains(scope) ? .blue : .gray)
                                .font(.system(size: 14))

                            Text(scope.rawValue)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedScopes.contains(scope) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

#Preview {
    CryptoOnrampExampleView()
}
