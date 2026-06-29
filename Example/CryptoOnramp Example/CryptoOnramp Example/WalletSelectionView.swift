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

    @ViewBuilder
    private func makeWalletButton(for wallet: Wallet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                selectedWallet = wallet
            } label: {
                makeWalletSelectionContent(for: wallet)
            }
            .buttonStyle(.plain)

            if shouldShowVerifyWalletButton(for: wallet) {
                Divider()

                Button {
                    startWalletOwnershipVerification(for: wallet)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield")

                        Text("Verify Wallet Ownership")
                            .font(.subheadline.weight(.semibold))

                        Spacer()
                    }
                    .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .disabled(isLoading.wrappedValue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedWallet == wallet ? Color.accentColor.opacity(0.12) : Color(.systemGroupedBackground))
        )
    }

    @ViewBuilder
    private func makeWalletSelectionContent(for wallet: Wallet) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(wallet.network.localizedCapitalized)
                        .font(.body)
                        .foregroundColor(.primary)

                    if isDisplayedAsVerified(wallet) {
                        Text("Verified")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background {
                                Capsule()
                                    .fill(Color.green.opacity(0.14))
                                    .overlay {
                                        Capsule()
                                            .stroke(Color.green.opacity(0.42), lineWidth: 1)
                                    }
                            }
                    }
                }

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
    }

    private func isDisplayedAsVerified(_ wallet: Wallet) -> Bool {
        // TODO: Remove this Solana override once the demo backend returns `verified_ownership`.
        wallet.verifiedOwnership || wallet.network == "solana"
    }

    private func shouldShowVerifyWalletButton(for wallet: Wallet) -> Bool {
        !isDisplayedAsVerified(wallet)
    }

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
