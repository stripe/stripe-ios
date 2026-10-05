//
//  AccountView.swift
//  KestrelBrokerageDemo
//

import SwiftUI

struct AccountView: View {
    @Environment(Portfolio.self) private var portfolio
    @Environment(ConnectService.self) private var connect
    @Binding var path: NavigationPath

    var body: some View {
        @Bindable var connect = connect

        List {
            Section {
                HStack(spacing: 14) {
                    Text("AR")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(width: 52, height: 52)
                        .background(Theme.gain, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alex Rivera")
                            .font(.system(size: 20, weight: .bold))
                        Text("Kestrel member since 2021")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section {
                row("Total value", value: portfolio.totalValue.currency)
                row("Buying power", value: portfolio.cash.currency)
            }

            Section("Transfers") {
                navigationRow("Withdraw", systemImage: "arrow.down.to.line", route: .withdraw)
                navigationRow("Payout methods", systemImage: "creditcard", route: .payoutMethods)
                navigationRow("Set up withdrawals", systemImage: "building.columns", route: .payoutInfo)
                Label("Transfer history", systemImage: "clock.arrow.circlepath")
                Label("Recurring deposits", systemImage: "repeat")
            }

            Section("Demo accounts") {
                merchantPicker("Set up withdrawals", selection: $connect.onboardingMerchantId)
                merchantPicker("Withdraw & payout methods", selection: $connect.payoutsMerchantId)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .foregroundStyle(Theme.textPrimary)
        .navigationTitle("Account")
        .toolbarBackground(Theme.background, for: .navigationBar)
        .task { await connect.prepare() }
    }

    private func navigationRow(_ title: String, systemImage: String, route: Route) -> some View {
        Button { path.append(route) } label: {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func merchantPicker(_ title: String, selection: Binding<String>) -> some View {
        Picker(title, selection: selection) {
            ForEach(connect.merchants) { merchant in
                Text(merchant.displayName ?? merchant.merchantId).tag(merchant.merchantId)
            }
        }
        .disabled(connect.merchants.isEmpty)
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
