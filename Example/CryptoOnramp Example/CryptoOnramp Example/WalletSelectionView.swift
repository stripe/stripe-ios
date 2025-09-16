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

    private var title: LocalizedStringKey {
        if wallets.isEmpty {
            "Add a crypto wallet"
        } else {
            "Select a wallet"
        }
    }

    private var subtitle: LocalizedStringKey {
        if wallets.isEmpty {
            "You’ll need to add at least one crypto wallet to continue."
        } else {
            "Select the crypto wallet you’d like to fund, or add a new one."
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "wallet.bifold")
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Color.secondary.opacity(0.2)
                            .cornerRadius(16)
                    }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

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
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .navigationTitle("Wallets")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, content: {
            Button("Add Wallet…") {
                showAttachWalletSheet = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading.wrappedValue)
            .opacity(isLoading.wrappedValue ? 0.5 : 1)
            .padding()
        })
        .navigationTitle("Identity Verification")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAttachWalletSheet) {
            AttachWalletAddressView(
                coordinator: coordinator,
                isWalletAttached: $isWalletAttached,
                onWalletAttached: { address, network in
                    // Refetch and select the newly added wallet
                    refreshWallets()
                }
            )
        }
        .onAppear {
            refreshWallets()
        }
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
        WalletSelectionView(
            coordinator: coordinator,
            customerId: "cus_example",
            onSelect: { _ in }
        )
    }
}
