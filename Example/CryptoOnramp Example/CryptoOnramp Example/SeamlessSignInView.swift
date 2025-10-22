//
//  SeamlessSignInView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/22/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

/// A view that allows the user to sign back in without manual authentication using a saved token.
struct SeamlessSignInView: View {
    let coordinator: CryptoOnrampCoordinator?
    let flowCoordinator: CryptoOnrampFlowCoordinator
    let email: String
    var onFailed: (() -> Void)? = nil

    @Environment(\.isLoading) private var isLoading
    @State private var alert: Alert?

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
            }
        })
    }

    private var shouldDisableContinueButton: Bool {
        isLoading.wrappedValue || coordinator == nil
    }

    private var attributedContinueString: AttributedString {
        var attributedString = AttributedString("Continue as \(email)?")
        if let emailRange = attributedString.range(of: email) {
            attributedString[emailRange].foregroundColor = .secondary
        }
        return attributedString
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            Spacer(minLength: 60)
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "person.circle")
                    .font(.system(size: 60))
                    .foregroundColor(Color.accentColor)
                    .padding()


                Text(attributedContinueString)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button("Continue") {
                    continueSeamlessSignIn()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(shouldDisableContinueButton)
                .opacity(shouldDisableContinueButton ? 0.5 : 1)

                Button("Not Me") {
                    // TODO: implement
                }
                .disabled(shouldDisableContinueButton)
                .opacity(shouldDisableContinueButton ? 0.5 : 1)
            }
            .disabled(shouldDisableContinueButton)
            .opacity(shouldDisableContinueButton ? 0.5 : 1)
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

    private func continueSeamlessSignIn() {
        guard let coordinator else { return }
        isLoading.wrappedValue = true
        Task {
            do {
                let result = try await APIClient.shared.createLinkAuthToken()
                try await coordinator.authenticateUserWithToken(result.linkAuthTokenClientSecret)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    flowCoordinator.startForExistingUser()
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(
                        title: "Failed to sign-in seamlessly. Please log in again manually.",
                        message: error.localizedDescription
                    )
                    onFailed?()
                    APIClient.shared.clearAuthState()
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        SeamlessSignInView(
            coordinator: coordinator,
            flowCoordinator: .init(),
            email: "demo@example.com"
        )
    }
}
