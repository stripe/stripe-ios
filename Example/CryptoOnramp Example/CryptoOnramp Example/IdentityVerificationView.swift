//
//  IdentityVerificationView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/10/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

struct IdentityVerificationView: View {
    let coordinator: CryptoOnrampCoordinator
    let onCompleted: () -> Void

    @Environment(\.isLoading) private var isLoading
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Identity Verification")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Verify Identity") {
                    startIdentityVerification()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isLoading.wrappedValue)
                .opacity(isLoading.wrappedValue ? 0.5 : 1)

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
            }
            .padding()
        }
        .navigationTitle("Identity Verification")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startIdentityVerification() {
        guard let topNav = UIApplication.shared.findTopNavigationController() else {
            errorMessage = "Unable to find view controller to present from."
            return
        }

        isLoading.wrappedValue = true
        errorMessage = nil

        Task {
            do {
                let result = try await coordinator.verifyIdentity(from: topNav)
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

