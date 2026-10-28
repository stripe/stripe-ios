//
//  IdentityVerificationView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/10/25.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// View with instructions for identity verification that serves as a presenter of the identity verification flow.
struct IdentityVerificationView: View {

    /// The coordinator to use to present identity verification UI.
    let coordinator: CryptoOnrampCoordinator

    /// Closure called when identity verification succeed, allowing parent flows to advance.
    let onCompleted: () -> Void

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

    // MARK: - View

    var body: some View {
        FlowStepContainerView(
            navigationTitle: "Identity Verification",
            systemImageName: "checkmark.shield",
            title: "Finish identity verification",
            message: "You’re almost done! To complete identity verification, Link will ask for:",
            buttonTitle: "Verify Identity",
            action: startIdentityVerification
        ) {
            makeInfoSection(
                systemImageName: "person.text.rectangle",
                title: "Photo of your ID",
                subtitle: "Scan your government-issued ID (driver’s license or passport)."
            )

            makeInfoSection(
                systemImageName: "person.fill.checkmark",
                title: "Take a selfie",
                subtitle: "This selfie is compared with your ID for verification."
            )
        }
        .alert(
            alert?.title ?? "Error",
            isPresented: isPresentingAlert,
            presenting: alert,
            actions: { _ in
                Button("OK") {}
            }, message: { alert in
                Text(alert.message)
            }
        )
    }

    @ViewBuilder
    private func makeInfoSection(systemImageName: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: systemImageName)

            VStack {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func startIdentityVerification() {
        guard let presentingViewController = UIApplication.shared.findTopNavigationController() else {
            alert = Alert(title: "Unable to present identity verification", message: "Unable to find view controller to present from.")
            return
        }

        isLoading.wrappedValue = true
        alert = nil

        Task {
            do {
                let result = try await coordinator.verifyIdentity(from: presentingViewController)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    switch result {
                    case .completed:
                        onCompleted()
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "Identity verification failed", message: error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        IdentityVerificationView(coordinator: coordinator, onCompleted: {})
    }
}
