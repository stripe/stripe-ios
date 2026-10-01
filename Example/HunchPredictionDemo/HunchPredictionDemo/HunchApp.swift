//
//  HunchApp.swift
//  HunchPredictionDemo
//

import SwiftUI

enum HunchTab: Hashable {
    case home
    case portfolio
    case account
}

@main
struct HunchApp: App {
    @State private var store = MarketStore()
    @State private var connect = ConnectService(appearance: { .hunch(surface: $0) })
    @State private var tab: HunchTab
    @State private var homePath = NavigationPath()
    @State private var portfolioPath = NavigationPath()
    @State private var accountPath = NavigationPath()
    @State private var order: OrderIntent?

    /// `-initialRoute <route>` opens straight to a screen, for rehearsing the demo.
    init() {
        var tab = HunchTab.home
        var homePath = NavigationPath()
        var portfolioPath = NavigationPath()
        var accountPath = NavigationPath()
        var order: OrderIntent?
        switch UserDefaults.standard.string(forKey: "initialRoute") {
        case "market": homePath.append("fed-dec")
        case "order": order = OrderIntent(marketId: "btc-150", outcomeId: "yes", side: .yes)
        case "portfolio": tab = .portfolio
        case "withdraw": tab = .portfolio; portfolioPath.append(CashOutRoute.withdraw)
        case "payoutMethods": tab = .account; accountPath.append(CashOutRoute.payoutMethods)
        case "setUp": tab = .account; accountPath.append(CashOutRoute.setUp)
        default: break
        }
        _tab = State(initialValue: tab)
        _homePath = State(initialValue: homePath)
        _portfolioPath = State(initialValue: portfolioPath)
        _accountPath = State(initialValue: accountPath)
        _order = State(initialValue: order)
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $tab) {
                Tab("Home", systemImage: "house.fill", value: HunchTab.home) {
                    NavigationStack(path: $homePath) {
                        HomeView(path: $homePath, order: $order)
                            .navigationDestination(for: String.self) { marketId in
                                MarketDetailView(marketId: marketId, order: $order)
                            }
                    }
                }
                Tab("Portfolio", systemImage: "chart.pie.fill", value: HunchTab.portfolio) {
                    NavigationStack(path: $portfolioPath) {
                        PortfolioView(path: $portfolioPath)
                            .navigationDestination(for: CashOutRoute.self, destination: cashOutDestination)
                    }
                }
                Tab("Account", systemImage: "person.crop.circle", value: HunchTab.account) {
                    NavigationStack(path: $accountPath) {
                        AccountView(path: $accountPath)
                            .navigationDestination(for: CashOutRoute.self, destination: cashOutDestination)
                    }
                }
            }
            .tint(Hunch.text)
            .preferredColorScheme(.light)
            .sheet(item: $order) { intent in
                OrderTicketView(intent: intent)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
            .environment(store)
            .environment(connect)
            .environment(\.embeddedCardStyle, EmbeddedCardStyle(
                card: Hunch.surface,
                skeleton: Hunch.hairline,
                shimmer: .white.opacity(0.7),
                error: Hunch.no,
                cornerRadius: 18
            ))
            .task { await connect.prepare() }
        }
    }

    @ViewBuilder
    private func cashOutDestination(_ route: CashOutRoute) -> some View {
        switch route {
        case .withdraw: WithdrawView()
        case .payoutMethods: PayoutMethodsView()
        case .setUp: SetUpWithdrawalsView()
        }
    }
}

struct AccountView: View {
    @Environment(MarketStore.self) private var store
    @Environment(ConnectService.self) private var connect
    @Binding var path: NavigationPath

    var body: some View {
        @Bindable var connect = connect

        List {
            Section {
                HStack(spacing: 14) {
                    Text("AR")
                        .font(.hunch(18, .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Hunch.brand, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alex Rivera").font(.hunch(19, .bold))
                        Text("Trading since 2024").font(.hunch(14)).foregroundStyle(Hunch.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
            Section("Cash out") {
                row("Cash out winnings", "arrow.down.to.line", .withdraw)
                row("Payout methods", "creditcard", .payoutMethods)
                row("Set up withdrawals", "person.text.rectangle", .setUp)
            }
            Section("Demo accounts") {
                picker("Set up withdrawals", selection: $connect.onboardingMerchantId)
                picker("Cash out & payout methods", selection: $connect.payoutsMerchantId)
            }
        }
        .navigationTitle("Account")
    }

    private func row(_ title: String, _ symbol: String, _ route: CashOutRoute) -> some View {
        Button { path.append(route) } label: {
            HStack {
                Label(title, systemImage: symbol).foregroundStyle(Hunch.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Hunch.secondary)
            }
        }
    }

    private func picker(_ title: String, selection: Binding<String>) -> some View {
        Picker(title, selection: selection) {
            ForEach(connect.merchants) { merchant in
                Text(merchant.displayName ?? merchant.merchantId).tag(merchant.merchantId)
            }
        }
        .disabled(connect.merchants.isEmpty)
    }
}
