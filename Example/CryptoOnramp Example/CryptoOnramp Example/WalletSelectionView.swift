//
//  WalletSelectionView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/15/25.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

typealias Wallet = CustomerWalletsResponse.Wallet

/// A view that allows the user to selecting an existing wallet and/or attach new ones.
struct WalletSelectionView: View {

    /// The coordinator used to attach new wallets.
    let coordinator: CryptoOnrampCoordinator

    /// Closure called once the user attempts to advance from this view with a wallet selected.
    let onCompleted: (Wallet) -> Void

    @State private var wallets: [Wallet] = []
    @State private var showAttachWalletSheet = false
    @State private var selectedWallet: Wallet?
    @State private var alert: Alert?

    @Environment(\.isLoading) private var isLoading

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
            }
        })
    }

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
                Image(systemName: "dollarsign.circle")
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

                if !wallets.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(wallets) { wallet in
                            WalletSelectionRowView(
                                wallet: wallet,
                                isSelected: selectedWallet == wallet,
                                isLoading: isLoading.wrappedValue,
                                onSelect: {
                                    selectedWallet = wallet
                                },
                                onVerifyWalletOwnership: {
                                    startWalletOwnershipVerification(for: wallet)
                                }
                            )
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

    // MARK: - WalletSelectionView

    private func startWalletOwnershipVerification(for wallet: Wallet) {
        guard let context = WalletOwnershipVerificationContext(wallet: wallet) else {
            alert = WalletOwnershipVerification.unavailableAlert
            return
        }

        WalletOwnershipVerification.startVerification(
            context: context,
            coordinator: coordinator,
            isLoading: isLoading,
            alert: $alert
        ) {
            refreshWallets(selectingWalletWithAddress: context.walletAddress, network: context.network)
        }
    }

    private func refreshWallets(selectingWalletWithAddress address: String? = nil, network: CryptoNetwork? = nil) {
        isLoading.wrappedValue = true
        Task {
            do {
                let response = try await APIClient.shared.fetchCustomerWallets()
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
                    alert = Alert(title: "Failed to fetch wallets", message: error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        WalletSelectionView(
            coordinator: coordinator,
            onCompleted: { _ in }
        )
    }
}
