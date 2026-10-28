//
//  UserAttestationPresentingView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 4/29/26.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// View with instructions for user attestation acceptance that presents the attestation modal.
struct UserAttestationPresentingView: View {

    /// The coordinator to use to present user attestation UI.
    let coordinator: CryptoOnrampCoordinator

    /// Closure called when the attestation is accepted, allowing parent flows to advance.
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

    var body: some View {
        FlowStepContainerView(
            navigationTitle: "User Attestation",
            systemImageName: "doc.plaintext",
            title: "Accept user attestation",
            message: "Before continuing, Link needs you to review and accept the user attestation.",
            buttonTitle: "Review Attestation",
            action: presentAttestation
        )
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

    private func presentAttestation() {
        guard let presentingViewController = UIApplication.shared.findTopNavigationController() else {
            alert = Alert(title: "Unable to present attestation", message: "Unable to find view controller to present from.")
            return
        }

        isLoading.wrappedValue = true
        alert = nil

        Task {
            do {
                let result = try await coordinator.presentUserAttestation(from: presentingViewController)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    switch result {
                    case .confirmed:
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
                    alert = Alert(title: "User attestation failed", message: error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        UserAttestationPresentingView(coordinator: coordinator, onCompleted: {})
    }
}
