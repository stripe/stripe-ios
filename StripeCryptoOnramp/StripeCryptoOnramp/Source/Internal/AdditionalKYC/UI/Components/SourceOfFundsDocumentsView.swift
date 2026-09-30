//
//  SourceOfFundsDocumentsView.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/24/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import SwiftUI

/// A summary of uploaded documents grouped by funds source, with an action to add another source.
struct SourceOfFundsDocumentsView: View {

    /// The displayed summary of a funds source whose full document state is owned by the caller.
    struct Source: Identifiable {

        // MARK: - Identifiable

        let id: String

        // MARK: - Source

        /// The name displayed above this source's documents.
        let name: String

        /// The uploaded filenames, in display order.
        let filenames: [String]
    }

    /// The destination requested by tapping a row.
    enum Selection: Equatable {

        /// Opens document collection for a new funds source.
        case addDocuments

        /// Opens the source and its uploaded documents corresponding to the source’s identifier.
        case source(id: String)
    }

    /// The funds sources to display, with stable identifiers used to look up their current document state.
    let sources: [Source]

    /// Called when the customer opens an existing source or chooses to add documents for a new one.
    let onSelection: (Selection) -> Void

    @Environment(\.displayScale) private var displayScale
    @ScaledMetric(relativeTo: .subheadline) private var sourceNameHeight = Typography.bodyMedium.lineHeight
    @ScaledMetric(relativeTo: .body) private var filenameHeight = Typography.bodyLarge.lineHeight

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            ForEach(sources) { source in
                sourceButton(for: source)
                    .overlay(alignment: .bottom) {
                        Color.primary.opacity(0.08)
                            .frame(height: 1 / displayScale)
                            .padding(.horizontal, 16)
                            .allowsHitTesting(false)
                    }
            }

            addDocumentsButton
        }
        .buttonStyle(.plain)
        .foregroundColor(.textPrimary)
        .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 24))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - SourceOfFundsDocumentsView

    private func sourceButton(for source: Source) -> some View {
        Button {
            onSelection(.source(id: source.id))
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(source.name)
                        .typography(.bodyMedium)
                        .foregroundColor(.textTertiary)
                        .frame(minHeight: sourceNameHeight, alignment: .leading)

                    ForEach(Array(source.filenames.enumerated()), id: \.offset) { _, filename in
                        documentLabel(filename: filename)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                chevron
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    private var addDocumentsButton: some View {
        Button {
            onSelection(.addDocuments)
        } label: {
            HStack(spacing: 16) {
                SwiftUI.Image(uiImage: Image.iconAdd.makeImage(template: true))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(12)
                    .background(Color.surfaceTertiary, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)

                Text(String.Localized.addDocuments)
                    .typography(.bodyLarge)
                    .frame(maxWidth: .infinity, alignment: .leading)

                chevron
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    private func documentLabel(filename: String) -> some View {
        HStack(spacing: 4) {
            SwiftUI.Image(uiImage: Image.iconDocument.makeImage(template: true))
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(.documentIcon)
                .accessibilityHidden(true)

            Text(filename)
                .typography(.bodyLarge)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minHeight: filenameHeight)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.surfaceTertiary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var chevron: some View {
        SwiftUI.Image(systemName: "chevron.forward")
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 12, height: 12)
            .foregroundColor(.documentBorder)
            .accessibilityHidden(true)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("No sources", traits: .sizeThatFitsLayout) {
    SourceOfFundsDocumentsView(sources: [], onSelection: { print("[Source of funds preview] \($0)") })
        .padding(20)
        .background(Color.surfacePrimary)
}

@available(iOS 17.0, *)
#Preview("Salary", traits: .sizeThatFitsLayout) {
    SourceOfFundsDocumentsView(sources: [.salaryPreview], onSelection: { print("[Source of funds preview] \($0)") })
        .padding(20)
        .background(Color.surfacePrimary)
}

@available(iOS 17.0, *)
#Preview("Salary and company profits", traits: .sizeThatFitsLayout) {
    SourceOfFundsDocumentsView(sources: [.salaryPreview, .companyProfitsPreview], onSelection: { print("[Source of funds preview] \($0)") })
        .padding(20)
        .background(Color.surfacePrimary)
}

private extension SourceOfFundsDocumentsView.Source {
    static var salaryPreview: Self {
        .init(id: "salary", name: "Salary", filenames: [
            "payslips-mar-25.pdf",
            "payslips-mar-25.pdf",
            "payslips-mar-25.pdf",
        ])
    }

    static var companyProfitsPreview: Self {
        .init(id: "company_profits", name: "Company profits", filenames: ["spacex-dividend-distribution.pdf"])
    }
}
#endif
