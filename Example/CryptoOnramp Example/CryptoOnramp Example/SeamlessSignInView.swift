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

    /// The coordinator used for seamless sign-in.
    let coordinator: CryptoOnrampCoordinator?

    /// The flow coordinator used to advance to the next steps after authentication.
    let flowCoordinator: CryptoOnrampFlowCoordinator

    /// The email address associated with the user capable of signing in seamlessly.
    let email: String

    /// Specifies an alert originating from this view to display by the parent.
    @Binding var alert: Alert?

    @Environment(\.isLoading) private var isLoading

    private var shouldDisableButtons: Bool {
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

                Button("Not Me") {
                    APIClient.shared.clearAuthState()
                }
            }
            .disabled(shouldDisableButtons)
            .opacity(shouldDisableButtons ? 0.5 : 1)
            .padding()
        }
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
            email: "demo@example.com",
            alert: .constant(nil)
        )
    }
}
