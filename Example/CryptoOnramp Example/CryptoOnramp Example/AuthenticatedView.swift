//
//  AuthenticatedView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/6/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A view to be displayed after a user has created an onramp session and is ready to check out.
struct AuthenticatedView: View {

    /// The coordinator to use for SDK operations like logging out
    let coordinator: CryptoOnrampCoordinator

    @State private var errorMessage: String?

    @Environment(\.isLoading) private var isLoading

    private var shouldDisableButtons: Bool {
        isLoading.wrappedValue
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Account")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button("Log out") {
                            logOut()
                        }
                        .font(.body)
                        .foregroundColor(.red)
                        .disabled(shouldDisableButtons)
                        .opacity(shouldDisableButtons ? 0.5 : 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

            }
            .padding()
        }
        .navigationTitle("Check Out")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func logOut() {
        guard let viewController = UIApplication.shared.findTopNavigationController() else {
            errorMessage = "Unable to find view controller to navigate from."
            return
        }

        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                try await coordinator.logOut()
                await MainActor.run {
                    isLoading.wrappedValue = false
                    viewController.popToRootViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Log out failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        AuthenticatedView(coordinator: coordinator)
    }
}
