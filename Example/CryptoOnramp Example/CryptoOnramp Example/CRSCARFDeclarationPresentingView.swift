//
//  CRSCARFDeclarationPresentingView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 4/29/26.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// View with instructions for CRS/CARF declaration acceptance that presents the declaration modal.
struct CRSCARFDeclarationPresentingView: View {

    /// The coordinator to use to present CRS/CARF declaration UI.
    let coordinator: CryptoOnrampCoordinator

    /// Closure called when the declaration is accepted, allowing parent flows to advance.
    let onCompleted: () -> Void

    @Environment(\.isLoading) private var isLoading
    @State private var alert: Alert?

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
            }
        })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "doc.plaintext")
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Color(.systemGroupedBackground)
                            .cornerRadius(16)
                    }

                VStack(spacing: 6) {
                    Text("Accept tax declaration")
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Before continuing, Link needs you to review and accept the CRS/CARF declaration.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button("Review Declaration") {
                presentDeclaration()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading.wrappedValue)
            .opacity(isLoading.wrappedValue ? 0.5 : 1)
            .padding()
        }
        .navigationTitle("Tax Declaration")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            alert?.title ?? "Error",
            isPresented: isPresentingAlert,
            presenting: alert,
            actions: { _ in
                Button("OK") {}
            }, message: { alert in
                Text(alert.message)
            }
        )
    }

    private func presentDeclaration() {
        guard let presentingViewController = UIApplication.shared.findTopNavigationController() else {
            alert = Alert(title: "Unable to present declaration", message: "Unable to find view controller to present from.")
            return
        }

        isLoading.wrappedValue = true
        alert = nil

        Task {
            do {
                let result = try await coordinator.presentCRSCARFDeclaration(from: presentingViewController)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    switch result {
                    case .confirmed:
                        onCompleted()
                    case .canceled:
                        break
                    @unknown default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "CRS/CARF declaration failed", message: error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        CRSCARFDeclarationPresentingView(coordinator: coordinator, onCompleted: {})
    }
}
