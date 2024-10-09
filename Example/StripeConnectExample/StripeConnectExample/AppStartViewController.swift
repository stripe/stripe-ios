//
//  ViewController.swift
//  StripeConnectExample
//
//  Created by Chris Mays on 8/21/24.
//

@_spi(PrivateBetaConnect) import StripeConnect
import SwiftUI
import UIKit

struct AppLoadingView: View {
    @Environment(\.viewControllerPresenter) var viewControllerPresenter
    @State var loadingState: LoadingState = .loading
    @State var displayLoadTimeReassurance: Bool = false
    @State var loadTimeReassuranceWorkItem: DispatchWorkItem?

    enum LoadingState {
        case loading
        case failed(reason: String)
        case finished
    }

    var body: some View {
        VStack(spacing: 10) {
            switch loadingState {
            case .loading:
                ProgressView()
                Text("Warming up the server… This may take several seconds")
                    .opacity(displayLoadTimeReassurance ? 1.0 : 0.0)
                    .multilineTextAlignment(.center)
            case .failed(let reason):
                Text("Failed to start app.")
                VStack {
                    Button {
                        load()
                    } label: {
                        Text("Reload")
                    }
                    Button {
                        viewControllerPresenter?.presentViewController(AppSettingsView(appInfo: nil).containerViewController)
                    } label: {
                        Text("App Settings")
                    }
                }
                Text("\(reason)")
                    .padding()
            case .finished:
                Text("")
            }
        }
        .onAppear {
            load()
        }
    }

    func load() {
        loadingState = .loading
        let workItem = DispatchWorkItem {
            withAnimation(.easeIn) {
                displayLoadTimeReassurance = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: workItem)
        loadTimeReassuranceWorkItem = workItem
        Task { @MainActor in
            defer {
                loadTimeReassuranceWorkItem?.cancel()
                loadTimeReassuranceWorkItem = nil
                displayLoadTimeReassurance = false
            }

            let appInfoResult = await API.appInfo()
            guard let appInfo = try? appInfoResult.get() else {
                var errorMessage = ""
                if case let .failure(error) = appInfoResult {
                    errorMessage = error.debugDescription
                }

                loadingState = .failed(reason: "\(errorMessage)")
                return
            }
            guard let firstMerchant = appInfo.availableMerchants.first else {
                loadingState = .failed(reason: "No merchants returned from api")
                return
            }

            STPAPIClient.shared.publishableKey = appInfo.publishableKey
            let selectedMerchant = AppSettings.shared.selectedMerchant(appInfo: appInfo) ?? firstMerchant
            viewControllerPresenter?.setRootViewController(MainViewController(appInfo: appInfo, merchant: selectedMerchant).embedInNavigationController())

        }
    }
}
