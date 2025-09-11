//
//  IdentityVerificationView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/10/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

/// View with instructions for identity verification that serves as a presenter of the identity verification flow.
struct IdentityVerificationView: View {

    /// The coordinator to use to present identity verification UI.
    let coordinator: CryptoOnrampCoordinator

    /// Closure called when identity verification succeed, allowing parent flows to advance.
    let onCompleted: () -> Void

    @Environment(\.isLoading) private var isLoading
    @State private var errorMessage: String?

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "checkmark.shield")
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Color.secondary.opacity(0.2)
                            .cornerRadius(16)
                    }

                VStack(spacing: 6) {
                    Text("Finish identity verification")
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("You’re almost done! To complete identity verification, Link will ask for:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

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

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom, content: {
            Button("Verify Identity") {
                startIdentityVerification()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading.wrappedValue)
            .opacity(isLoading.wrappedValue ? 0.5 : 1)
            .padding()
        })
        .navigationTitle("Identity Verification")
        .navigationBarTitleDisplayMode(.inline)
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
            errorMessage = "Unable to find view controller to present from."
            return
        }

        isLoading.wrappedValue = true
        errorMessage = nil

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
                    errorMessage = "Identity verification failed: \(error.localizedDescription)"
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
