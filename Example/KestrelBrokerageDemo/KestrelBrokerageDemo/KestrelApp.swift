//
//  KestrelApp.swift
//  KestrelBrokerageDemo
//

import SwiftUI

enum Route: Hashable {
    case account
    case payoutInfo
    case withdraw
    case payoutMethods
}

@main
struct KestrelApp: App {
    @State private var portfolio = Portfolio()
    @State private var connect = ConnectService(appearance: { .kestrel(surface: $0) })
    @State private var path = NavigationPath()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                HomeView(path: $path)
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .account:
                            AccountView(path: $path)
                        case .payoutInfo:
                            PayoutInfoView()
                        case .withdraw:
                            WithdrawView()
                        case .payoutMethods:
                            PayoutMethodsView()
                        }
                    }
            }
            .tint(Theme.gain)
            .preferredColorScheme(.dark)
            .environment(portfolio)
            .environment(connect)
            .environment(\.embeddedCardStyle, EmbeddedCardStyle(
                card: Theme.card,
                skeleton: Theme.cardRaised,
                shimmer: .white.opacity(0.08),
                error: Theme.loss
            ))
            .task { await connect.prepare() }
            .onAppear(perform: openInitialRoute)
        }
    }

    /// `-initialRoute payoutInfo` opens straight to a screen, for rehearsing the demo.
    private func openInitialRoute() {
        switch UserDefaults.standard.string(forKey: "initialRoute") {
        case "account": path.append(Route.account)
        case "payoutInfo": path.append(Route.payoutInfo)
        case "withdraw": path.append(Route.withdraw)
        case "payoutMethods": path.append(Route.payoutMethods)
        default: break
        }
    }
}
