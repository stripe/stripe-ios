//
//  WalletOwnershipVerificationView.swift
//  CryptoOnramp Example
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// A view that demonstrates the two-step wallet ownership verification flow:
/// 1. Request a challenge for a registered wallet address.
/// 2. Submit a signature over the challenge message.
///
/// In a real app, step 2 would route the `challenge.message` to the merchant's
/// wallet stack for signing (e.g. via `eth_sign` or `ed25519`). This example
/// uses a placeholder signature to illustrate the API surface.
struct WalletOwnershipVerificationView: View {

    /// The coordinator used to request and verify wallet ownership.
    let coordinator: CryptoOnrampCoordinator

    /// Callback invoked when ownership verification completes successfully.
    let onVerified: ((ConsumerWallet) -> Void)?

    @State private var walletAddress: String = ""
    @State private var selectedNetwork: CryptoNetwork = .ethereum
    @State private var pendingChallenge: WalletOwnershipChallenge?
    @State private var signature: String = ""
    @State private var errorMessage: String?

    @Environment(\.isLoading) private var isLoading
    @Environment(\.dismiss) private var dismiss
    @FocusState private var walletFieldFocused: Bool

    private var isRequestChallengeDisabled: Bool {
        isLoading.wrappedValue || walletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isSubmitSignatureDisabled: Bool {
        isLoading.wrappedValue || signature.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let challenge = pendingChallenge {
                        // Step 2: show challenge message and collect signature
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Challenge received. Sign the message below with your wallet and paste the signature.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Challenge ID: \(challenge.challengeId)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("Expires: \(challenge.expiresAt)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        FormField("Message to Sign") {
                            Text(challenge.message)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }

                        FormField("Signature") {
                            TextField("Paste signature here", text: $signature, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .lineLimit(3...6)
                        }

                        if let errorMessage {
                            ErrorMessageView(message: errorMessage)
                        }

                        Button("Submit Signature") {
                            submitSignature(challenge: challenge)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSubmitSignatureDisabled)
                        .opacity(isSubmitSignatureDisabled ? 0.5 : 1)

                        Button("Start Over") {
                            pendingChallenge = nil
                            signature = ""
                            errorMessage = nil
                        }
                        .foregroundColor(.secondary)

                    } else {
                        // Step 1: collect wallet address and request challenge
                        Text("Enter a registered wallet address to start the ownership verification challenge.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        FormField("Wallet Address") {
                            TextField("Enter wallet address", text: $walletAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($walletFieldFocused)
                        }

                        FormField("Network") {
                            Picker("Network", selection: $selectedNetwork) {
                                ForEach(CryptoNetwork.allCases, id: \.rawValue) { network in
                                    Text(network.rawValue.localizedCapitalized).tag(network)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let errorMessage {
                            ErrorMessageView(message: errorMessage)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Verify Wallet Ownership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                if pendingChallenge == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Request Challenge") {
                            requestChallenge()
                        }
                        .disabled(isRequestChallengeDisabled)
                        .opacity(isRequestChallengeDisabled ? 0.5 : 1)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                walletFieldFocused = true
            }
        }
    }

    private func requestChallenge() {
        isLoading.wrappedValue = true
        errorMessage = nil

        let address = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let challenge = try await coordinator.getWalletOwnershipChallenge(
                    walletAddress: address,
                    network: selectedNetwork
                )
                await MainActor.run {
                    isLoading.wrappedValue = false
                    pendingChallenge = challenge
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Failed to get challenge: \(error.localizedDescription)"
                }
            }
        }
    }

    private func submitSignature(challenge: WalletOwnershipChallenge) {
        isLoading.wrappedValue = true
        errorMessage = nil

        let sig = signature.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let wallet = try await coordinator.submitWalletOwnershipSignature(
                    challengeId: challenge.challengeId,
                    signature: sig
                )
                await MainActor.run {
                    isLoading.wrappedValue = false
                    onVerified?(wallet)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Signature verification failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        WalletOwnershipVerificationView(coordinator: coordinator, onVerified: nil)
    }
}
