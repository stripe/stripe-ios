//
//  PayoutInfoView.swift
//  KestrelBrokerageDemo
//

@_spi(DashboardOnly) import StripeConnect
import SwiftUI

struct PayoutInfoView: View {
    @Environment(ConnectService.self) private var connect
    @Environment(Portfolio.self) private var portfolio
    @Environment(\.dismiss) private var dismiss

    @State private var componentManager: EmbeddedComponentManager?
    @State private var isComplete = false
    @State private var heroAppeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                availableCard

                if isComplete {
                    CompletionCard(amount: portfolio.cash) { dismiss() }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.92).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else {
                    onboardingCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                footer
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationTitle("Payout information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .task {
            await connect.prepare()
            if componentManager == nil, connect.isReady {
                componentManager = connect.makeComponentManager(for: connect.onboardingMerchantId, surface: .page)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.05)) {
                heroAppeared = true
            }
        }
        .sensoryFeedback(.success, trigger: isComplete) { _, new in new }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.gain.opacity(0.14))
                    .frame(width: 64, height: 64)
                    .scaleEffect(heroAppeared ? 1 : 0.4)
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.gain)
                    .symbolEffect(.bounce, value: heroAppeared)
            }

            Text("Where should we send your money?")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Withdrawals from Kestrel land here. Update your bank details any time — it only takes a minute.")
                .font(.system(size: 16))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(heroAppeared ? 1 : 0)
        .offset(y: heroAppeared ? 0 : 16)
        .padding(.top, 8)
    }

    private var availableCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Available to withdraw")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                Text(portfolio.cash.currency)
                    .font(.rounded(24, .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Label(isComplete ? "Ready" : "Needs bank", systemImage: isComplete ? "checkmark.circle.fill" : "clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isComplete ? Theme.gain : Color.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((isComplete ? Theme.gain : Color.orange).opacity(0.14), in: Capsule())
                .contentTransition(.symbolEffect(.replace))
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .opacity(heroAppeared ? 1 : 0)
        .offset(y: heroAppeared ? 0 : 24)
    }

    private var onboardingCard: some View {
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
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                    isComplete = true
                }
            }
        )
        // Flush on the page: the component pads its own content by ~16pt, so undo most of the screen margin.
        .padding(.horizontal, -16)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
            Text("Bank details are encrypted and verified by Stripe.")
        }
        .font(.system(size: 12))
        .foregroundStyle(Theme.textSecondary)
        .frame(maxWidth: .infinity)
    }
}

private struct CompletionCard: View {
    let amount: Double
    let onDone: () -> Void

    @State private var drawCheck = false
    @State private var ringScale: CGFloat = 0.6

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Theme.gain.opacity(0.25), lineWidth: 10)
                    .frame(width: 92, height: 92)
                    .scaleEffect(ringScale)
                Circle()
                    .fill(Theme.gain)
                    .frame(width: 72, height: 72)
                    .scaleEffect(ringScale)
                CheckmarkShape()
                    .trim(from: 0, to: drawCheck ? 1 : 0)
                    .stroke(.black, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    .frame(width: 30, height: 24)
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                Text("You're all set")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Your \(amount.currency) withdrawal will arrive in 1–2 business days.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            PillButton(title: "Done", action: onDone)
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { ringScale = 1 }
            withAnimation(.easeOut(duration: 0.45).delay(0.2)) { drawCheck = true }
        }
    }
}

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
