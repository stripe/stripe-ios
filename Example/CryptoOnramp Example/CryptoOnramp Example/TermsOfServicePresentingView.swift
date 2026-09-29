//
//  TermsOfServicePresentingView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/8/26.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// A view that checks for and presents partner terms of service after KYC information collection.
struct TermsOfServicePresentingView: View {

    /// The coordinator to use to check for and present partner terms of service.
    let coordinator: CryptoOnrampCoordinator

    /// A closure called when the terms are accepted or no presentation is required.
    let onCompleted: () -> Void

    @Environment(\.isLoading) private var isLoading
    @State private var alert: Alert?
    @State private var shouldAdvanceAfterDismissingAlert = false

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                dismissAlert()
            }
        })
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Color(.systemGroupedBackground)
                            .cornerRadius(16)
                    }

                VStack(spacing: 6) {
                    Text("Review terms of service")
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Before continuing, Link needs to check whether you must review and accept the partner terms of service.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button("Continue") {
                presentTermsOfServiceIfNeeded()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading.wrappedValue)
            .opacity(isLoading.wrappedValue ? 0.5 : 1)
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            alert?.title ?? "Error",
            isPresented: isPresentingAlert,
            presenting: alert,
            actions: { _ in
                Button("OK") {
                    dismissAlert()
                }
            }, message: { alert in
                Text(alert.message)
            }
        )
    }

    private func presentTermsOfServiceIfNeeded() {
        guard let presentingViewController = UIApplication.shared.findTopNavigationController() else {
            shouldAdvanceAfterDismissingAlert = false
            alert = Alert(
                title: "Unable to present terms of service",
                message: "Unable to find view controller to present from."
            )
            return
        }

        isLoading.wrappedValue = true
        shouldAdvanceAfterDismissingAlert = false
        alert = nil

        Task {
            do {
                let result = try await coordinator.presentTermsOfServiceIfNeeded(from: presentingViewController)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    switch result {
                    case .accepted:
                        onCompleted()
                    case .notRequired:
                        shouldAdvanceAfterDismissingAlert = true
                        alert = Alert(
                            title: "Terms of service not required",
                            message: "The customer has already accepted the current terms of service or is not required to accept them."
                        )
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    shouldAdvanceAfterDismissingAlert = false
                    alert = Alert(title: "Terms of service failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func dismissAlert() {
        alert = nil
        guard shouldAdvanceAfterDismissingAlert else { return }

        shouldAdvanceAfterDismissingAlert = false
        onCompleted()
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        TermsOfServicePresentingView(coordinator: coordinator, onCompleted: {})
    }
}
