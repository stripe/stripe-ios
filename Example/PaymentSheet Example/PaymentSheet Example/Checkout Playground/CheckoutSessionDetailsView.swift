//
//  CheckoutSessionDetailsView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 8/11/26.
//

import SwiftUI

struct CheckoutSessionDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var diagnostics: CheckoutSessionDiagnostics

    let sessionID: String

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
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    CheckoutDiagnosticSectionHeader(title: "Checkout session")
                    CheckoutDiagnosticIdentifierCard(
                        title: "Session ID",
                        value: sessionID,
                        systemImage: "cart.fill"
                    )

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
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Session diagnostics")
                    .font(.title2.bold())
                Text("IDs and Stripe API activity for this checkout")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close session diagnostics")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
