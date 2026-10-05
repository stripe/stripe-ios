//
//  PayoutMethodsView.swift
//  KestrelBrokerageDemo
//

@_spi(DashboardOnly) import StripeConnect
import SwiftUI

/// Kestrel's "Manage your details" screen with Stripe's payout methods component embedded inline.
struct PayoutMethodsView: View {
    @Environment(ConnectService.self) private var connect

    @State private var componentManager: EmbeddedComponentManager?
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("alex.rivera@example.com")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Manage your details")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Choose where your withdrawals go. Add a bank account or a debit card for instant transfers.")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background { AuroraBackground() }
                .clipped()

                EmbeddedComponentCard(
                    componentManager: componentManager,
                    surface: .page,
                    skeleton: .payoutMethods,
                    skeletonHeight: 256,
                    cacheKey: "kestrel.payoutMethods",
                    makeComponent: { $0.createInlinePayoutMethodsViewController() }
                )
                // The component pads its own content by ~16pt; this lands it on Kestrel's 20pt margin.
                .padding(.horizontal, 4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)

                // Kestrel's own UI continues below the embedded component and moves with it as it resizes.
                WithdrawalSettings()
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.bottom, 40)
        }
        .background(Theme.background)
        .navigationTitle("Payout methods")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .task {
            await connect.prepare()
            if componentManager == nil, connect.isReady {
                componentManager = connect.makeComponentManager(for: connect.payoutsMerchantId, surface: .page)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.1)) { appeared = true }
        }
    }
}

/// Native Kestrel settings shown below the embedded payout methods component.
private struct WithdrawalSettings: View {
    @State private var instantWithdrawals = true
    @State private var autoWithdrawDividends = false

    private let recent: [(date: String, amount: Double, destination: String, instant: Bool)] = [
        ("Sep 24", 500, "Stripe Test Bank ••6789", false),
        ("Sep 12", 1_200, "Visa ••5556", true),
        ("Aug 30", 250, "Stripe Test Bank ••6789", false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 0) {
                header("Withdrawal settings")
                toggleRow("Instant withdrawals",
                          detail: "Arrives in minutes to eligible debit cards. 1.5% fee.",
                          isOn: $instantWithdrawals)
                Divider().overlay(Theme.hairline)
                toggleRow("Auto-withdraw dividends",
                          detail: "Send dividends to your default payout method.",
                          isOn: $autoWithdrawDividends)
            }

            VStack(alignment: .leading, spacing: 0) {
                header("Recent withdrawals")
                ForEach(Array(recent.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 14) {
                        Image(systemName: item.instant ? "bolt.fill" : "arrow.down.to.line")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.gain)
                            .frame(width: 36, height: 36)
                            .background(Theme.gain.opacity(0.14), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.destination)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(item.date) · \(item.instant ? "Instant" : "Standard")")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text(item.amount.currency)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.vertical, 12)
                    if index < recent.count - 1 { Divider().overlay(Theme.hairline) }
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Why can't I remove my default account?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Choose a new default first, then remove the old one.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .sensoryFeedback(.selection, trigger: instantWithdrawals)
        .sensoryFeedback(.selection, trigger: autoWithdrawDividends)
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.bottom, 8)
    }

    private func toggleRow(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .tint(Theme.gain)
        .padding(.vertical, 12)
    }
}
