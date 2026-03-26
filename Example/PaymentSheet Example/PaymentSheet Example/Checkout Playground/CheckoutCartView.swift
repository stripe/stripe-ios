//
//  CheckoutCartView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/2/26.
//

@_spi(STP) import StripePayments
@_spi(CheckoutSessionsPreview) @_spi(STP) import StripePaymentSheet
import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct CheckoutCartView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var checkout: Checkout

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var copiedSessionID = false

    init(clientSecret: String) {
        _checkout = StateObject(wrappedValue: Checkout(clientSecret: clientSecret))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if let session = checkout.session {
                    CheckoutCartContentView(
                        checkout: checkout,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage
                    )
                    .overlay(alignment: .bottom) {
                        if session.totals != nil {
                            CheckoutCartPaymentButton(
                                checkout: checkout,
                                onDismiss: { dismiss() }
                            )
                        }
                    }
                } else if isLoading {
                    ProgressView("Loading Cart...")
                } else {
                    VStack {
                        Text("Failed to load cart.")
                        Button("Retry") {
                            Task { await loadCheckout() }
                        }
                        .padding()
                    }
                }

                if isLoading && checkout.session != nil {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationTitle("Your Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let session = checkout.session {
                        Button {
                            UIPasteboard.general.string = session.id
                            Task { @MainActor in
                                withAnimation {
                                    copiedSessionID = true
                                }
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                withAnimation {
                                    copiedSessionID = false
                                }
                            }
                        } label: {
                            Image(systemName: copiedSessionID ? "checkmark" : "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("Copy Checkout Session ID")
                        .accessibilityIdentifier("checkout-playground-copy-session-id")
                    }
                }
            }
            .task {
                await loadCheckout()
            }
        }
    }

    private func loadCheckout() async {
        isLoading = true
        errorMessage = nil
        do {
            try await checkout.load()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
