//
//  LogInSignUpView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/20/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

struct LogInSignUpView: View {
    enum AuthMode { case logIn, signUp }

    let coordinator: CryptoOnrampCoordinator?
    let flowCoordinator: CryptoOnrampFlowCoordinator
    @Binding var livemode: Bool

    @Environment(\.isLoading) private var isLoading

    @State private var authMode: AuthMode = .logIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var selectedScopes: Set<OAuthScopes> = Set(OAuthScopes.requiredScopes)
    @State private var alert: Alert?

    @FocusState private var isEmailFieldFocused: Bool

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })
    }

    private var isContinueDisabled: Bool {
        isLoading.wrappedValue || email.isEmpty || password.isEmpty || coordinator == nil
    }

    private var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("", selection: $authMode) {
                    Text("Log In").tag(AuthMode.logIn)
                    Text("Sign Up").tag(AuthMode.signUp)
                }
                .pickerStyle(.segmented)

                FormField("Email") {
                    TextField("Enter email address", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isEmailFieldFocused)
                        .submitLabel(.next)
                }

                FormField("Password") {
                    SecureField("Enter password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit { if !isContinueDisabled { continueTapped() } }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Livemode", isOn: $livemode)
                        .font(.headline)
                        .disabled(isRunningOnSimulator)

                    if isRunningOnSimulator {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.octagon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Livemode is not supported in the simulator.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                OAuthScopeSelector(
                    selectedScopes: $selectedScopes,
                    onOnrampScopesSelected: {
                        selectedScopes = Set(OAuthScopes.requiredScopes)
                    },
                    onAllScopesSelected: {
                        selectedScopes = Set(OAuthScopes.allScopes)
                    }
                )

                Button(authMode == .logIn ? "Log In" : "Sign Up") {
                    isEmailFieldFocused = false
                    continueTapped()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isContinueDisabled)
                .opacity(isContinueDisabled ? 0.5 : 1)
            }
            .padding()
        }
        .alert(
            alert?.title ?? "Error",
            isPresented: isPresentingAlert,
            presenting: alert,
            actions: { _ in Button("OK") {} },
            message: { alert in Text(alert.message) }
        )
    }

    // MARK: - Actions

    private func continueTapped() {
        switch authMode {
        case .logIn: logIn()
        case .signUp: signUp()
        }
    }

    private func logIn() {
        isLoading.wrappedValue = true
        Task {
            do {
                _ = try await APIClient.shared.logIn(email: email, password: password, livemode: livemode)
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
        isLoading.wrappedValue = true
        Task {
            do {
                _ = try await APIClient.shared.signUp(email: email, password: password, livemode: livemode)
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

                await MainActor.run {
                    isLoading.wrappedValue = false
                    switch authorizationResult {
                    case .consented(let customerId):
                        flowCoordinator.startForExistingUser(customerId: customerId)
                    case .denied:
                        alert = Alert(title: "Authorization Denied", message: "Authorization was denied.")
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                }
            } else {
                flowCoordinator.startForNewUser(email: email, selectedScopes: scopes)
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
            livemode: .constant(false)
        )
    }
}
