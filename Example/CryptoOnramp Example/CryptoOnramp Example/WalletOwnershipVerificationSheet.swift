//
//  WalletOwnershipVerificationSheet.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/21/26.
//

import Foundation
import SwiftUI
import UIKit

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// A sheet for copying a wallet ownership challenge and submitting its signature.
struct WalletOwnershipVerificationSheet: View {

    /// The challenge and mode to display.
    let session: WalletOwnershipVerificationSession

    /// The coordinator used to submit the signature.
    let coordinator: CryptoOnrampCoordinator

    /// Called when Stripe returns the wallet as verified.
    let onVerified: @MainActor () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isLoading) private var isLoading

    @State private var alert: Alert?
    @State private var signature: String

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
            }
        })
    }

    private var signatureToSubmit: String {
        signature.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSubmitDisabled: Bool {
        isLoading.wrappedValue || signatureToSubmit.isEmpty
    }

    /// Creates a wallet ownership verification sheet.
    /// - Parameters:
    ///   - session: The challenge and mode to display.
    ///   - coordinator: The coordinator used to submit the signature.
    ///   - onVerified: Called when Stripe returns the wallet as verified.
    init(
        session: WalletOwnershipVerificationSession,
        coordinator: CryptoOnrampCoordinator,
        onVerified: @escaping @MainActor () -> Void
    ) {
        self.session = session
        self.coordinator = coordinator
        self.onVerified = onVerified
        _signature = State(initialValue: session.isTestMode ? "abcd" : "")
    }

    // MARK: - View

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Sign the challenge message with your wallet, then paste the signature below.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    FormField("Challenge Message") {
                        Text(session.challenge.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.separator))
                            }
                        Button {
                            UIPasteboard.general.string = session.challenge.message
                        } label: {
                            Label("Copy Message", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }

                    FormField("Signature") {
                        TextField("Paste signature", text: $signature)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        if session.isTestMode {
                            Text("test mode supports a constant 'abcd' as a valid signature")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Verify Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitSignature()
                    }
                    .disabled(isSubmitDisabled)
                    .opacity(isSubmitDisabled ? 0.5 : 1)
                }
            }
        }
        .loadingOverlay(isVisible: isLoading.wrappedValue)
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

    // MARK: - WalletOwnershipVerificationSheet

    private func submitSignature() {
        isLoading.wrappedValue = true
        alert = nil

        Task {
            do {
                let wallet = try await coordinator.submitWalletOwnershipSignature(
                    challengeId: session.challenge.challengeId,
                    signature: signatureToSubmit
                )

                await MainActor.run {
                    isLoading.wrappedValue = false
                    if wallet.verifiedOwnership {
                        dismiss()
                        onVerified()
                    } else {
                        // The request to verify the wallet succeeded, but the backend is still erroneously reporting that
                        // `verifiedOwnership` is `false`. This is not an expected use case.
                        alert = Alert(
                            title: "Wallet verification failed",
                            message: "Stripe did not mark this wallet as verified. Please try again."
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(
                        title: "Wallet verification failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
}
