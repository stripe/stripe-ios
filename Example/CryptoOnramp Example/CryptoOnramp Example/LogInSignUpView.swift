//
//  LogInSignUpView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/20/25.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// The first screen in the example app flow, allowing a user to log in and sign up using the demo backend, and begin link authentication.
struct LogInSignUpView: View {

    /// The coordinator used for link authentication.
    let coordinator: CryptoOnrampCoordinator?

    /// The flow coordinator used to advance to the next steps after authentication.
    let flowCoordinator: CryptoOnrampFlowCoordinator

    /// Whether livemode is enabled, which can be toggled from this view.
    @Binding var livemode: Bool

    /// Whether to use level 0 KYC collection mode from the KYC info screen.
    @Binding var isL0KYCModeEnabled: Bool

    /// Specifies an alert originating from this view to display by the parent.
    @Binding var alert: Alert?

    @Environment(\.isLoading) private var isLoading

    @State private var email: String = ""
    @State private var selectedScopes: Set<OAuthScopes> = Set(OAuthScopes.requiredScopes)
    @State private var isShowingScopesSheet = false

    @State private var password: String = ""

    @FocusState private var isEmailFieldFocused: Bool
    @FocusState private var isPasswordFieldFocused: Bool

    private var shouldDisableButtons: Bool {
        if isLoading.wrappedValue || email.isEmpty || coordinator == nil {
            return true
        }
        if !DemoConfig.isPasswordlessEnabled && password.isEmpty {
            return true
        }
        return false
    }

    /// The password to send to the backend: either the user-entered one, or the demo password.
    private var effectivePassword: String {
        DemoConfig.isPasswordlessEnabled ? (DemoConfig.passwordlessPassword ?? "") : password
    }

    private var kycInfoCollectionMode: KYCInfoView.CollectionMode {
        isL0KYCModeEnabled ? .kycLevel0 : .original
    }

    private var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle")
                    .font(.system(size: 60))
                    .foregroundColor(Color.accentColor)
                    .padding()

                FormField("Email") {
                    TextField("Enter email address", text: $email)
                        .font(.title3)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isEmailFieldFocused)
                        .submitLabel(DemoConfig.isPasswordlessEnabled ? .done : .next)
                }

                if !DemoConfig.isPasswordlessEnabled {
                    FormField("Password") {
                        SecureField("Enter password", text: $password)
                            .font(.title3)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isPasswordFieldFocused)
                            .submitLabel(.done)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Toggle(isOn: $livemode) {
                        Label("Livemode", systemImage: "server.rack")
                    }
                    // Livemode is disabled on the simulator.
                    .disabled(isRunningOnSimulator)

                    Toggle(isOn: $isL0KYCModeEnabled) {
                        Label("L0 KYC Mode", systemImage: "person.text.rectangle")
                    }

                    Divider()

                    Button {
                        isShowingScopesSheet = true
                    } label: {
                        Label("OAuth Scopes…", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button("Log In") {
                    dismissKeyboard()
                    logIn()
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Sign Up") {
                    dismissKeyboard()
                    signUp()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .disabled(shouldDisableButtons)
            .opacity(shouldDisableButtons ? 0.5 : 1)
            .padding()
        }
        .sheet(isPresented: $isShowingScopesSheet) {
            OAuthScopeSelectionView(
                selectedScopes: $selectedScopes,
                onOnrampScopesSelected: {
                    selectedScopes = Set(OAuthScopes.requiredScopes)
                },
                onAllScopesSelected: {
                    selectedScopes = Set(OAuthScopes.allScopes)
                }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Actions

    private func dismissKeyboard() {
        isEmailFieldFocused = false
        isPasswordFieldFocused = false
    }

    private func logIn() {
        if DemoConfig.isPasswordlessEnabled && !DemoConfig.isEmailAllowed(email) {
            alert = Alert(title: "Email Not Allowed", message: "This email is not on the allowed list for demo mode.")
            return
        }
        isLoading.wrappedValue = true
        Task {
            do {
                try await APIClient.shared.logIn(email: email, password: effectivePassword, livemode: livemode)
                await proceedToLinkAuthorization()
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "Log In Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func signUp() {
        if DemoConfig.isPasswordlessEnabled && !DemoConfig.isEmailAllowed(email) {
            alert = Alert(title: "Email Not Allowed", message: "This email is not on the allowed list for demo mode.")
            return
        }
        isLoading.wrappedValue = true
        Task {
            do {
                try await APIClient.shared.signUp(email: email, password: effectivePassword, livemode: livemode)
                await proceedToLinkAuthorization()
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "Sign Up Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func proceedToLinkAuthorization() async {
        guard let coordinator else { return }
        let scopes = Array(selectedScopes)

        do {
            if try await coordinator.hasLinkAccount(with: email) {
                // Create Link auth intent on demo backend using selected scopes
                let createAuthIntentResponse = try await APIClient.shared.createAuthIntent(oauthScopes: scopes)

                guard let navController = UIApplication.shared.findTopNavigationController() else {
                    await MainActor.run {
                        isLoading.wrappedValue = false
                        alert = Alert(title: "Error", message: "Unable to find view controller to present from.")
                    }
                    return
                }

                let authorizationResult = try await coordinator.authorize(linkAuthIntentId: createAuthIntentResponse.authIntentId, from: navController)

                if case let .consented(cryptoCustomerId) = authorizationResult {
                    try await APIClient.shared.saveUser(cryptoCustomerId: cryptoCustomerId)
                }

                await MainActor.run {
                    isLoading.wrappedValue = false
                    switch authorizationResult {
                    case .consented:
                        flowCoordinator.startForExistingUser(kycInfoCollectionMode: kycInfoCollectionMode)
                    case .denied:
                        alert = Alert(title: "Authorization Denied", message: "Authorization was denied.")
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                }
            } else {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    flowCoordinator.startForNewUser(
                        email: email,
                        selectedScopes: scopes,
                        kycInfoCollectionMode: kycInfoCollectionMode
                    )
                }
            }
        } catch {
            await MainActor.run {
                isLoading.wrappedValue = false
                alert = Alert(title: "Error", message: "Please try signing in again. \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        LogInSignUpView(
            coordinator: coordinator,
            flowCoordinator: .init(),
            livemode: .constant(false),
            isL0KYCModeEnabled: .constant(false),
            alert: .constant(nil)
        )
    }
}
