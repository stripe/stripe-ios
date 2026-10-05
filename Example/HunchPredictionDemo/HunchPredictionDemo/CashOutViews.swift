//
//  CashOutViews.swift
//  HunchPredictionDemo
//

@_spi(DashboardOnly) import StripeConnect
import SwiftUI

enum CashOutRoute: Hashable {
    case withdraw
    case payoutMethods
    case setUp
}

/// Hunch's cash-out screen with Stripe's payout session component embedded flush on the page.
struct WithdrawView: View {
    @Environment(ConnectService.self) private var connect
    @Environment(MarketStore.self) private var store

    @State private var componentManager: EmbeddedComponentManager?
    @State private var displayedAmount: Double = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hunch is sending you")
                        .font(.hunch(16, .medium))
                        .foregroundStyle(Hunch.secondary)
                    Text(displayedAmount.dollars)
                        .font(.hunchNumber(48))
                        .foregroundStyle(Hunch.text)
                        .contentTransition(.numericText(value: displayedAmount))
                    Label("Instant to eligible debit cards", systemImage: "bolt.fill")
                        .font(.hunch(14, .semibold))
                        .foregroundStyle(Hunch.yes)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("How do you want to get paid?")
                        .font(.hunch(18, .bold))
                        .foregroundStyle(Hunch.text)
                        .padding(.horizontal, 16)
                    EmbeddedComponentCard(
                        componentManager: componentManager,
                        surface: .page,
                        skeletonHeight: 360,
                        makeComponent: { $0.createInlinePayoutSessionViewController() }
                    )
                    // The component pads its own content by ~16pt, which lines up with Hunch's margin.
                }
            }
            .padding(.bottom, 32)
        }
        .background(Hunch.background)
        .navigationTitle("Cash out")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await connect.prepare()
            if componentManager == nil, connect.isReady {
                componentManager = connect.makeComponentManager(for: connect.payoutsMerchantId, surface: .page)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.15)) { displayedAmount = store.cash }
        }
    }
}

/// Hunch's payout methods screen with Stripe's payout methods component embedded flush on the page.
struct PayoutMethodsView: View {
    @Environment(ConnectService.self) private var connect
    @State private var componentManager: EmbeddedComponentManager?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Payout methods")
                        .font(.hunch(30, .bold))
                        .foregroundStyle(Hunch.text)
                    Text("Where your winnings go. Add a debit card to cash out instantly.")
                        .font(.hunch(15))
                        .foregroundStyle(Hunch.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                EmbeddedComponentCard(
                    componentManager: componentManager,
                    surface: .page,
                    skeleton: .payoutMethods,
                    skeletonHeight: 256,
                    cacheKey: "hunch.payoutMethods",
                    makeComponent: { $0.createInlinePayoutMethodsViewController() }
                )

                // Hunch's own UI continues below the embedded component and moves with it as it resizes.
                CashOutPreferences()
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }
            .padding(.bottom, 32)
        }
        .background(Hunch.background)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await connect.prepare()
            if componentManager == nil, connect.isReady {
                componentManager = connect.makeComponentManager(for: connect.payoutsMerchantId, surface: .page)
            }
        }
    }
}

/// First-time withdrawal setup with Stripe's account onboarding embedded in a card.
struct SetUpWithdrawalsView: View {
    @Environment(ConnectService.self) private var connect
    @Environment(\.dismiss) private var dismiss

    @State private var componentManager: EmbeddedComponentManager?
    @State private var isComplete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Set up withdrawals")
                        .font(.hunch(30, .bold))
                        .foregroundStyle(Hunch.text)
                    Text("We need a few details before you can cash out your winnings.")
                        .font(.hunch(15))
                        .foregroundStyle(Hunch.secondary)
                }
                if isComplete {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Hunch.yes)
                            .symbolEffect(.bounce, value: isComplete)
                        Text("You're ready to cash out").font(.hunch(20, .bold)).foregroundStyle(Hunch.text)
                        HunchPrimaryButton(title: "Done") { dismiss() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Hunch.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                } else {
                    EmbeddedComponentCard(
                        componentManager: componentManager,
                        surface: .page,
                        skeletonHeight: 420,
                        makeComponent: { manager in
                            var options = AccountCollectionOptions()
                            options.fields = .eventuallyDue
                            return manager.createInlineAccountOnboardingViewController(collectionOptions: options)
                        },
                        onExit: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { isComplete = true }
                        }
                    )
                    // Flush on the page: the component pads its own content by ~16pt, matching Hunch's margin.
                    .padding(.horizontal, -16)
                }
            }
            .padding(16)
        }
        .background(Hunch.background)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: isComplete) { _, new in new }
        .task {
            await connect.prepare()
            if componentManager == nil, connect.isReady {
                componentManager = connect.makeComponentManager(for: connect.onboardingMerchantId, surface: .page)
            }
        }
    }
}

/// Native Hunch preferences shown below the embedded payout methods component.
private struct CashOutPreferences: View {
    @State private var instantCashOut = true
    @State private var autoCashOut = false

    private let recent: [(date: String, amount: Double, destination: String, instant: Bool)] = [
        ("Sep 27", 400, "Visa ••5556", true),
        ("Sep 14", 86.20, "Stripe Test Bank ••6789", false),
        ("Aug 31", 212.75, "Stripe Test Bank ••6789", false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Cash-out preferences")
                    .font(.hunch(18, .bold))
                    .foregroundStyle(Hunch.text)
                    .padding(.bottom, 4)
                toggleRow("Instant cash out", "Winnings hit eligible debit cards in minutes.", $instantCashOut)
                Divider().overlay(Hunch.hairline)
                toggleRow("Auto cash out on settlement", "Send winnings out as soon as a market settles.", $autoCashOut)
            }
            .padding(16)
            .background(Hunch.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                Text("Recent cash outs")
                    .font(.hunch(18, .bold))
                    .foregroundStyle(Hunch.text)
                    .padding(.bottom, 4)
                ForEach(Array(recent.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: item.instant ? "bolt.fill" : "building.columns.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Hunch.yes)
                            .frame(width: 34, height: 34)
                            .background(Hunch.yesTint, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.destination).font(.hunch(15, .medium)).foregroundStyle(Hunch.text)
                            Text("\(item.date) · \(item.instant ? "Instant" : "Standard")")
                                .font(.hunch(13))
                                .foregroundStyle(Hunch.secondary)
                        }
                        Spacer()
                        Text(item.amount.dollars).font(.hunchNumber(16, .semibold)).foregroundStyle(Hunch.text)
                    }
                    .padding(.vertical, 11)
                    if index < recent.count - 1 { Divider().overlay(Hunch.hairline) }
                }
            }

            Label("Payouts are handled securely by Stripe.", systemImage: "lock.fill")
                .font(.hunch(12, .medium))
                .foregroundStyle(Hunch.secondary)
                .frame(maxWidth: .infinity)
        }
        .sensoryFeedback(.selection, trigger: instantCashOut)
        .sensoryFeedback(.selection, trigger: autoCashOut)
    }

    private func toggleRow(_ title: String, _ detail: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.hunch(15, .semibold)).foregroundStyle(Hunch.text)
                Text(detail).font(.hunch(13)).foregroundStyle(Hunch.secondary)
            }
        }
        .tint(Hunch.brand)
        .padding(.vertical, 10)
    }
}
