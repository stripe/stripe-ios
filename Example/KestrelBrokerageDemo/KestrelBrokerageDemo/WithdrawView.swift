//
//  WithdrawView.swift
//  KestrelBrokerageDemo
//

@_spi(DashboardOnly) import StripeConnect
import SwiftUI

/// Kestrel's own withdraw screen with Stripe's payout session component embedded inline.
///
/// Kestrel owns the header and amount; the component owns choosing the destination,
/// standard vs. instant, and confirming (its dialogs open as native sheets).
struct WithdrawView: View {
    @Environment(ConnectService.self) private var connect
    @Environment(Portfolio.self) private var portfolio

    @State private var componentManager: EmbeddedComponentManager?
    @State private var displayedAmount: Double = 0
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero

                VStack(alignment: .leading, spacing: 12) {
                    Text("How do you want to get paid?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 16)
                    EmbeddedComponentCard(
                        componentManager: componentManager,
                        surface: .page,
                        skeletonHeight: 360,
                        makeComponent: { $0.createInlinePayoutSessionViewController() }
                    )
                }
                // The component pads its own content by ~16pt; this lands it on Kestrel's 20pt margin.
                .padding(.horizontal, 4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)

                Label("Payouts are sent by Stripe on Kestrel's behalf.", systemImage: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 40)
        }
        .background(Theme.background)
        .navigationTitle("Withdraw")
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
            withAnimation(.easeOut(duration: 1.1).delay(0.15)) { displayedAmount = portfolio.cash }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kestrel is sending you")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            Text(displayedAmount, format: .currency(code: "USD"))
                .font(.rounded(52, .bold))
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText(value: displayedAmount))
                .monospacedDigit()
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                Text("Instant to eligible debit cards")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.gain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 36)
        .background { AuroraBackground() }
        .clipped()
    }
}

/// Slowly drifting glows behind the hero, echoing Stripe's hosted payout pages in Kestrel's palette.
struct AuroraBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.gain.opacity(0.35))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: drift ? 140 : 90, y: drift ? -40 : 10)
            Circle()
                .fill(Color(red: 0.1, green: 0.6, blue: 0.5).opacity(0.3))
                .frame(width: 220, height: 220)
                .blur(radius: 80)
                .offset(x: drift ? -120 : -60, y: drift ? 50 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}
