//
//  AttachWalletAddressView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/20/25.
//

import SwiftUI

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A view shown in a sheet to attach a crypto wallet address to the current user’s account.
struct AttachWalletAddressView: View {

    /// The coordinator used to submit the wallet address.
    let coordinator: CryptoOnrampCoordinator

    /// Binding to inform presenting view that a wallet was successfully attached.
    @Binding var isWalletAttached: Bool

    /// Callback invoked on successful attach with the address and network used.
    let onWalletAttached: ((String, CryptoNetwork) -> Void)?

    @State private var walletAddress: String = "0x4242424242424242424242424242424242424242"
    @State private var selectedNetwork: CryptoNetwork = .ethereum
    @State private var errorMessage: String?

    @Environment(\.isLoading) private var isLoading
    @Environment(\.dismiss) private var dismiss
    @FocusState private var walletFieldFocused: Bool

    private var isSubmitDisabled: Bool {
        isLoading.wrappedValue || walletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Attach a wallet address to your account.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

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
                .padding()
            }
            .navigationTitle("Wallet Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submit()
                    }
                    .disabled(isSubmitDisabled)
                    .opacity(isSubmitDisabled ? 0.5 : 1)
                }
            }
        }
        .onAppear {
            // Focus and select the text so the user can quickly delete the default address if needed.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                walletFieldFocused = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                }
            }
        }
    }

    private func submit() {
        isLoading.wrappedValue = true
        errorMessage = nil

        let address = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                try await coordinator.collectWalletAddress(walletAddress: address, network: selectedNetwork)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    isWalletAttached = true
                    onWalletAttached?(address, selectedNetwork)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Attach wallet failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        AttachWalletAddressView(coordinator: coordinator, isWalletAttached: .constant(false), onWalletAttached: nil)
    }
}
