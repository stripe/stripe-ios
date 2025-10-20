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
    let coordinator: CryptoOnrampCoordinator?
    let flowCoordinator: CryptoOnrampFlowCoordinator
    @Binding var livemode: Bool

    @Environment(\.isLoading) private var isLoading

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var selectedScopes: Set<OAuthScopes> = Set(OAuthScopes.requiredScopes)
    @State private var alert: Alert?
    @State private var isShowingScopesSheet = false

    @FocusState private var isEmailFieldFocused: Bool
    @FocusState private var isPasswordFieldFocused: Bool

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
            }
        })
    }

    private var shouldDisableButtons: Bool {
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
                        .focused($isPasswordFieldFocused)
                        .submitLabel(.done)

                }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Toggle(isOn: $livemode) {
                        Label("Livemode", systemImage: "server.rack")
                    }
                    // Livemode is disabled on the simulator.
                    .disabled(isRunningOnSimulator)

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
                    isEmailFieldFocused = false
                    isPasswordFieldFocused = false
                    logIn()
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Sign Up") {
                    isEmailFieldFocused = false
                    isPasswordFieldFocused = false
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
