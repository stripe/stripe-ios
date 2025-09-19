//
//  WalletSelectionView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/15/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

typealias Wallet = CustomerWalletsResponse.Wallet

/// A view that allows the user to selecting an existing wallet and/or attach new ones.
struct WalletSelectionView: View {

    /// The coordinator used to attach new wallets.
    let coordinator: CryptoOnrampCoordinator

    /// The id of the customer.
    let customerId: String

    /// Closure called once the user attempts to advance from this view with a wallet selected.
    let onCompleted: (Wallet) -> Void

    @State private var wallets: [Wallet] = []
    @State private var errorMessage: String?
    @State private var showAttachWalletSheet = false
    @State private var selectedWallet: Wallet?

    @Environment(\.isLoading) private var isLoading

    private var title: LocalizedStringKey {
        wallets.isEmpty ?  "Add a crypto wallet" : "Select a wallet"
    }

    private var subtitle: LocalizedStringKey {
        if wallets.isEmpty {
            "You’ll need to add at least one crypto wallet to continue."
        } else {
            "Select the crypto wallet you’d like to fund, or add a new one."
        }
    }

    private var primaryButtonTitle: LocalizedStringKey {
        wallets.isEmpty ? "Add Wallet…" : "Next"
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "wallet.bifold")
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Color(.systemGroupedBackground)
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

                if !wallets.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(wallets) { wallet in
                            makeWalletButton(for: wallet)
                        }
                    }

                    Button("Add another wallet…") {
                        showAttachWalletSheet = true
                    }
                    .disabled(isLoading.wrappedValue)
                    .opacity(isLoading.wrappedValue ? 0.5 : 1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle("Wallets")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, content: {
            Button(primaryButtonTitle) {
                if wallets.isEmpty {
                    showAttachWalletSheet = true
                } else if let selectedWallet {
                    onCompleted(selectedWallet)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading.wrappedValue)
            .opacity(isLoading.wrappedValue ? 0.5 : 1)
            .padding()
        })
        .sheet(isPresented: $showAttachWalletSheet) {
            AttachWalletAddressView(
                coordinator: coordinator,
                onWalletAttached: { address, network in
                    refreshWallets(selectingWalletWithAddress: address, network: network)
                }
            )
        }
        .onAppear {
            refreshWallets()
        }
    }

    // MARK: - WalletSelectionView

    @ViewBuilder
    private func makeWalletButton(for wallet: Wallet) -> some View {
        Button {
            selectedWallet = wallet
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wallet.network.localizedCapitalized)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(wallet.walletAddress)
                        .font(.caption2.monospaced())
                        .foregroundColor(.secondary)
                }

                Spacer()

                if selectedWallet == wallet {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedWallet == wallet ? Color.accentColor.opacity(0.12) : Color(.systemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private func refreshWallets(selectingWalletWithAddress address: String? = nil, network: CryptoNetwork? = nil) {
        isLoading.wrappedValue = true
        errorMessage = nil
        Task {
            do {
                let response = try await APIClient.shared.fetchCustomerWallets(cryptoCustomerToken: customerId)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    wallets = response.data

                    let matchingWallet = wallets.first { wallet in
                        wallet.walletAddress == address && wallet.network == network?.rawValue
                    }

                    if let matchingWallet {
                        selectedWallet = matchingWallet
                    } else if selectedWallet == nil {
                        selectedWallet = wallets.first
                    }
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
            onCompleted: { _ in }
        )
    }
}
