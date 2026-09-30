//
//  AuthenticatedUserToolbarItemModifier.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/29/25.
//

import SwiftUI
import UIKit

@_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
@_spi(CryptoOnrampAlpha) import StripePaymentSheet

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
    @State private var isPresentingUpdateAddress = false
    @State private var isFulfillingAdditionalKYC = false
    @State private var alert: Alert?
    @State private var customerInformationTextToCopy: String?

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
                customerInformationTextToCopy = nil
            }
        })
    }

    func body(content: Content) -> some View {
        content
        .sheet(isPresented: $isPresentingUpdateAddress) {
            UpdateAddressView { address in
                // Wait for dismissal to be fully complete, otherwise, we'll try to
                // present a view controller while another is already attached.
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    verifyKYC(updatedAddress: address)
                }
            }
        }
        .alert(
            alert?.title ?? "Error",
            isPresented: isPresentingAlert,
            presenting: alert,
            actions: { _ in
                if let customerInformationTextToCopy {
                    Button("Copy") {
                        UIPasteboard.general.string = customerInformationTextToCopy
                    }
                }

                Button("OK") {}
            }, message: { alert in
                Text(alert.message)
            }
        )
        .toolbar {
            if isShown {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            verifyKYC()
                        } label: {
                            Label("Verify KYC Info…", systemImage: "doc.text.magnifyingglass")
                        }

                        Button {
                            fulfillAdditionalKYCRequirement()
                        } label: {
                            Label("Check Additional KYC Requirements…", systemImage: "doc.text")
                        }

                        Button {
                            checkCustomerInformation()
                        } label: {
                            Label("Check Customer Information…", systemImage: "person.text.rectangle")
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

    private func checkCustomerInformation() {
        isLoading.wrappedValue = true

        Task {
            do {
                let customerInformation = try await APIClient.shared.fetchCustomerInfo()
                let formattedCustomerInformation = String(describing: customerInformation)

                await MainActor.run {
                    isLoading.wrappedValue = false
                    customerInformationTextToCopy = formattedCustomerInformation
                    alert = Alert(
                        title: "Customer Information",
                        message: formattedCustomerInformation
                    )
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    customerInformationTextToCopy = nil
                    alert = Alert(
                        title: "Failed to fetch customer information",
                        message: error.localizedDescription
                    )
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

    private func verifyKYC(updatedAddress: Address? = nil) {
        guard let presentingVC = UIApplication.shared.findTopViewController() else { return }
        Task {
            do {
                let result = try await coordinator.verifyKYCInfo(updatedAddress: updatedAddress, from: presentingVC)
                switch result {
                case .confirmed:
                    await MainActor.run {
                        alert = Alert(title: "Success", message: "KYC information confirmed.")
                    }
                case .updateAddress:
                    await MainActor.run {
                        isPresentingUpdateAddress = true
                    }
                case .canceled:
                    break
                @unknown default:
                    break
                }
            } catch {
                await MainActor.run {
                    alert = Alert(title: "KYC verification failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func fulfillAdditionalKYCRequirement() {
        guard !isFulfillingAdditionalKYC else { return }
        isFulfillingAdditionalKYC = true

        Task { @MainActor in
            defer { isFulfillingAdditionalKYC = false }

            guard let presentingViewController = UIApplication.shared.findTopNavigationController() else {
                alert = Alert(title: "Unable to collect documents", message: "Unable to find a view controller to present from.")
                return
            }

            do {
                let result = try await coordinator.fulfillAdditionalKYCRequirement(from: presentingViewController)
                switch result {
                case .submitted:
                    alert = Alert(title: "Document submitted", message: "Your document is being verified.")
                case .pendingVerification:
                    alert = Alert(title: "Verification pending", message: "Your information is still being reviewed.")
                case .canceled:
                    break
                case .notRequired:
                    alert = Alert(title: "No document required", message: "No additional document is needed right now.")
                @unknown default:
                    alert = Alert(title: "Unable to collect documents", message: "Received an unexpected result from document collection.")
                }
            } catch {
                alert = Alert(title: "Unable to collect documents", message: error.localizedDescription)
            }
        }
    }
}
