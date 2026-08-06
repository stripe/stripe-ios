//
//  WalletSelectionRowView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 6/29/26.
//

import SwiftUI

/// A selectable wallet row with optional wallet ownership verification controls.
struct WalletSelectionRowView: View {

    /// The wallet displayed by this row.
    let wallet: Wallet

    /// Whether the wallet is currently selected.
    let isSelected: Bool

    /// Whether wallet actions should be disabled.
    let isLoading: Bool

    /// Called when the row is selected.
    let onSelect: () -> Void

    /// Called when the wallet ownership verification action is selected.
    let onVerifyWalletOwnership: () -> Void

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onSelect) {
                makeWalletSelectionContent()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if shouldShowVerifyWalletButton {
                Divider()
                    .padding(.horizontal)

                Button(action: onVerifyWalletOwnership) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield")
                            .font(.caption)

                        Text("Verify Ownership")
                            .font(.caption.weight(.medium))

                        Spacer()
                    }
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.systemGroupedBackground))
        )
    }

    // MARK: - WalletSelectionRowView

    @ViewBuilder
    private func makeWalletSelectionContent() -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(wallet.network.localizedCapitalized)
                        .font(.body)
                        .foregroundColor(.primary)

                    if isDisplayedAsVerified {
                        verifiedBadge
                    }
                }

                Text(wallet.walletAddress)
                    .font(.caption2.monospaced())
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var isDisplayedAsVerified: Bool {
        wallet.verifiedOwnership
    }

    private var shouldShowVerifyWalletButton: Bool {
        !isDisplayedAsVerified
    }

    @ViewBuilder
    private var verifiedBadge: some View {
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

#Preview {
    VStack(spacing: 8) {
        WalletSelectionRowView(
            wallet: Wallet(
                id: "verified_wallet",
                object: "crypto.consumer_wallet",
                livemode: false,
                network: "solana",
                walletAddress: "example_wallet_address",
                verifiedOwnership: true
            ),
            isSelected: true,
            isLoading: false,
            onSelect: {},
            onVerifyWalletOwnership: {}
        )

        WalletSelectionRowView(
            wallet: Wallet(
                id: "unverified_wallet",
                object: "crypto.consumer_wallet",
                livemode: false,
                network: "ethereum",
                walletAddress: "example_wallet_address",
                verifiedOwnership: false
            ),
            isSelected: false,
            isLoading: false,
            onSelect: {},
            onVerifyWalletOwnership: {}
        )
    }
    .padding()
}
