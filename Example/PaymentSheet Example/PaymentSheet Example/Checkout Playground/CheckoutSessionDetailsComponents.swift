//
//  CheckoutSessionDetailsComponents.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 8/11/26.
//

import SwiftUI

private enum CheckoutDiagnosticStyle {
    static let stripe = Color(red: 99.0 / 255.0, green: 91.0 / 255.0, blue: 1)
}

struct CheckoutDiagnosticSectionHeader: View {
    let title: String
    var count: Int?

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(0.4)

            if let count {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(CheckoutDiagnosticStyle.stripe)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(CheckoutDiagnosticStyle.stripe.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 4)
    }
}

struct CheckoutDiagnosticIdentifierCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            diagnosticIcon(systemImage)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(value)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)
            CheckoutDiagnosticCopyButton(value: value)
        }
        .padding(14)
        .checkoutDiagnosticCard()
    }
}

struct CheckoutDiagnosticNavigationCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            diagnosticIcon(systemImage)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(value)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .checkoutDiagnosticCard()
    }
}

struct CheckoutDiagnosticRequestCard: View {
    let request: CheckoutSessionDiagnostics.Request

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                diagnosticIcon("arrow.up.arrow.down")

                VStack(alignment: .leading, spacing: 2) {
                    Text(request.displayName)
                        .font(.subheadline.weight(.medium))
                    Text(request.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
                CheckoutDiagnosticCopyButton(value: request.requestID)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(request.requestID)
                    .font(.caption.monospaced())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(request.endpoint)
                    .font(.caption2.monospaced())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.leading, 44)
        }
        .padding(14)
        .checkoutDiagnosticCard()
    }
}

struct CheckoutDiagnosticEmptyRequestsView: View {
    var body: some View {
        HStack(spacing: 12) {
            diagnosticIcon("arrow.triangle.2.circlepath")

            VStack(alignment: .leading, spacing: 3) {
                Text("Waiting for Stripe")
                    .font(.subheadline.weight(.medium))
                Text("Request IDs appear here as Checkout communicates with Stripe.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .checkoutDiagnosticCard()
    }
}

struct CheckoutDiagnosticCopyButton: View {
    let value: String

    @State private var isCopied = false
    @State private var resetTask: Task<Void, Never>?

    var body: some View {
        Button {
            UIPasteboard.general.string = value
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeInOut(duration: 0.15)) {
                isCopied = true
            }
            resetTask?.cancel()
            resetTask = Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    isCopied = false
                }
            }
        } label: {
            Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                .font(.caption.weight(.semibold))
                .foregroundColor(CheckoutDiagnosticStyle.stripe)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(CheckoutDiagnosticStyle.stripe.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCopied ? "Copied" : "Copy \(value)")
        .onDisappear {
            resetTask?.cancel()
        }
    }
}

private func diagnosticIcon(_ systemName: String) -> some View {
    Image(systemName: systemName)
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(CheckoutDiagnosticStyle.stripe)
        .frame(width: 32, height: 32)
        .background(CheckoutDiagnosticStyle.stripe.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 9))
}

private extension View {
    func checkoutDiagnosticCard() -> some View {
        background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 0.5)
            )
    }
}
