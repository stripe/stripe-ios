//
//  WalletSelectionView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/15/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

struct WalletSelectionView: View {
    let coordinator: CryptoOnrampCoordinator
    let customerId: String
    let onSelect: (CustomerWalletsResponse.Wallet) -> Void

    @State private var wallets: [CustomerWalletsResponse.Wallet] = []
    @State private var errorMessage: String?
    @State private var showAttachWalletSheet = false
    @State private var isWalletAttached = false

    @Environment(\.isLoading) private var isLoading

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if wallets.isEmpty {
                    VStack(spacing: 12) {
                        Text("No wallets found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add a wallet to continue.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Add Wallet") { showAttachWalletSheet = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isLoading.wrappedValue)
                            .opacity(isLoading.wrappedValue ? 0.5 : 1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select a Wallet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        ForEach(wallets, id: \.id) { wallet in
                            Button(action: { onSelect(wallet) }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(wallet.network.localizedCapitalized)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(wallet.walletAddress)
                                        .font(.footnote.monospaced())
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        Button("Add Wallet") { showAttachWalletSheet = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isLoading.wrappedValue)
                            .opacity(isLoading.wrappedValue ? 0.5 : 1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }

                if let errorMessage { ErrorMessageView(message: errorMessage) }
            }
            .padding()
        }
        .navigationTitle("Wallets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAttachWalletSheet) {
            AttachWalletAddressView(
                coordinator: coordinator,
                isWalletAttached: $isWalletAttached,
                onWalletAttached: { address, network in
                    // Refetch on success
                    refreshWallets()
                }
            )
        }
        .onAppear { refreshWallets() }
    }

    private func refreshWallets() {
        isLoading.wrappedValue = true
        errorMessage = nil
        Task {
            do {
                let response = try await APIClient.shared.fetchCustomerWallets(cryptoCustomerToken: customerId)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    wallets = response.data
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    errorMessage = "Failed to fetch wallets: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        WalletSelectionView(coordinator: coordinator, customerId: "cus_example", onSelect: { _ in })
    }
}
