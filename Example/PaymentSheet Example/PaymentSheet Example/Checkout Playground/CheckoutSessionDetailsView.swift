//
//  CheckoutSessionDetailsView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 8/11/26.
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutSessionDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var diagnostics: CheckoutSessionDiagnostics
    @ObservedObject var checkout: CheckoutController

    @ViewBuilder
    var body: some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }

    private var content: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    CheckoutDiagnosticSectionHeader(title: "Checkout session")
                    NavigationLink {
                        CheckoutSessionDebugView(checkout: checkout)
                    } label: {
                        CheckoutDiagnosticNavigationCard(
                            title: "Checkout Session",
                            value: checkout.session.id,
                            systemImage: "cart.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View Checkout Session details")

                    CheckoutDiagnosticSectionHeader(
                        title: "API activity",
                        count: diagnostics.requests.count
                    )
                    .padding(.top, 10)

                    if diagnostics.requests.isEmpty {
                        CheckoutDiagnosticEmptyRequestsView()
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(diagnostics.requests) { request in
                                CheckoutDiagnosticRequestCard(request: request)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Session diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct CheckoutSessionDebugView: View {
    @ObservedObject var checkout: CheckoutController

    private var sessionDebugDescription: String {
        checkout.session.debugDescription
    }

    var body: some View {
        ScrollView {
            Text(sessionDebugDescription)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Checkout Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CheckoutDiagnosticCopyButton(
                    value: sessionDebugDescription,
                    accessibilityLabel: "Copy Checkout Session details"
                )
            }
        }
    }
}
