//
//  AuthenticatedUserToolbarItemModifier.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/29/25.
//

import SwiftUI
import UIKit

@_spi(STP) import StripeCryptoOnramp
@_spi(STP) import StripePaymentSheet

extension View {

    /// Convenience modifier to show a trailing toolbar item for accessing user-related actions, such as "log out".
    /// - Parameters:
    ///   - isShown: Whether the toolbar item is shown.
    ///   - coordinator: The coordinator used to perform user-related actions.
    ///   - flowCoordinator: The flow coordinator used to manipulate the navigation stack.
    /// - Returns: The modified view.
    func authenticatedUserToolbar(isShown: Bool, coordinator: CryptoOnrampCoordinator, flowCoordinator: CryptoOnrampFlowCoordinator?) -> some View {
        self.modifier(AuthenticatedUserToolbarItemModifier(isShown: isShown, coordinator: coordinator, flowCoordinator: flowCoordinator))
    }
}

private struct AuthenticatedUserToolbarItemModifier: ViewModifier {
    let isShown: Bool
    let coordinator: CryptoOnrampCoordinator
    let flowCoordinator: CryptoOnrampFlowCoordinator?

    @Environment(\.isLoading) private var isLoading

    func body(content: Content) -> some View {
        content
        .toolbar {
            if isShown {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            verifyKYC()
                        } label: {
                            Label("Verify KYC Info…", systemImage: "doc.text.magnifyingglass")
                        }

                        Divider()

                        Button(role: .destructive) {
                            logOut()
                        } label: {
                            Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                                .tint(.red)
                        }
                    } label: {
                        Image(systemName: "person.fill")
                    }
                    .disabled(isLoading.wrappedValue)
                    .opacity(isLoading.wrappedValue ? 0.5 : 1)
                    .tint(.accentColor)
                }
            }
        }
     }

    private func logOut() {
        isLoading.wrappedValue = true

        // Note: We deliberately are not calling `APIClient.shared.clearAuthTokens()` here.
        // Otherwise, exercising seamless sign-in functionality would be a bit awkward,
        // given that you'd need to restart the app in a logged-in state to test the functionality.
        // Therefore, logging out will take you back to the root view, which will display in
        // the seamless sign-in state.

        Task {
            do {
                try await coordinator.logOut()

                await MainActor.run {
                    isLoading.wrappedValue = false
                    flowCoordinator?.path = []
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    flowCoordinator?.path = []
                    print("Log out failed. Still returning to root view. Error: \(error)")
                }
            }
        }
    }

    private func verifyKYC() {
        guard let presentingVC = UIApplication.shared.findTopViewController() else { return }
        Task {
            do {
                let result = try await coordinator.verifyKYCInfo(from: presentingVC)
                switch result {
                case .confirmed:
                    print("KYC verification confirmed")
                case .updateAddress:
                    print("KYC verification: user chose to update address")
                case .canceled:
                    print("KYC verification canceled")
                @unknown default:
                    break
                }
            } catch {
                print("Error during KYC verification: \(error)")
            }
        }
    }
}
