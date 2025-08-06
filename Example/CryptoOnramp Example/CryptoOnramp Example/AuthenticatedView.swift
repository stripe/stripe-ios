//
//  AuthenticatedView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/6/25.
//

import SwiftUI

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A view to be displayed after a user has successfully authenticated, with more SDK options to exercise.
struct AuthenticatedView: View {

    /// The coordinator to use for SDK operations like identity verification and KYC info collection.
    let coordinator: CryptoOnrampCoordinator

    /// The customer id of the authenticated user.
    let customerId: String

    // MARK: - View
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button("Verify Identity") {
                    if let viewController = UIApplication.shared.findTopNavigationController() {
                        Task {
                            do {
                                let result = try await coordinator.promptForIdentityVerification(from: viewController)
                                switch result {
                                case .completed:
                                    await MainActor.run {
                                        // TODO: implement
                                    }
                                case .canceled:
                                    // do nothing, verification canceled.
                                    break
                                @unknown default:
                                    // do nothing, verification canceled.
                                    break
                                }
                            } catch {
                                // TODO: implement
                                //errorMessage = error.localizedDescription
                            }
                        }
                    } else {
                        // TODO: show error message
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                VStack(spacing: 8) {
                    Text("Customer ID")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Text(customerId)
                        .font(.subheadline.monospaced())
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Authenticated")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AuthenticatedPreviewView: View {
    @State var coordinator: CryptoOnrampCoordinator?
    var body: some View {
        NavigationView {
            if let coordinator = coordinator {
                AuthenticatedView(coordinator: coordinator, customerId: "cus_example123456789")
            }
        }
        .onAppear {
            STPAPIClient.shared.setUpPublishableKey()
            Task {
                let coordinator = try? await CryptoOnrampCoordinator.create(appearance: .init())

                await MainActor.run {
                    self.coordinator = coordinator
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AuthenticatedPreviewView()
    }
}
