//
//  CryptoOnrampExampleView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/24/25.
//

import SwiftUI
import StripeCore

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

struct CryptoOnrampExampleView: View {
    @State private var coordinator: CryptoOnrampCoordinator?
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationView {
            ScrollView {

            }
            .navigationTitle("CryptoOnramp Example")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            initializeLinkController()
        }
        .overlay(
            ZStack {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        )
    }

    private func initializeLinkController() {
        STPAPIClient.shared.publishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"

        Task {
            do {
                let coordinator = try await CryptoOnrampCoordinator.create(appearance: .init())

                await MainActor.run {
                    self.coordinator = coordinator
                    self.isLoading = false
                    self.statusMessage = "CryptoOnrampCoordinator initialized successfully"
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to initialize CryptoOnrampCoordinator: \(error.localizedDescription)"
                    self.statusMessage = nil
                }
            }
        }
    }
}

#Preview {
    CryptoOnrampExampleView()
}
