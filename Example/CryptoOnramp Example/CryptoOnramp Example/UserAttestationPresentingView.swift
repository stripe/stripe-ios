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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "doc.plaintext")
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Color(.systemGroupedBackground)
                            .cornerRadius(16)
                    }

                VStack(spacing: 6) {
                    Text("Accept user attestation")
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Before continuing, Link needs you to review and accept the user attestation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button("Review Attestation") {
                presentAttestation()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading.wrappedValue)
            .opacity(isLoading.wrappedValue ? 0.5 : 1)
            .padding()
        }
        .navigationTitle("User Attestation")
        .navigationBarTitleDisplayMode(.inline)
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
