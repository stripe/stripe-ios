//
//  DocumentFileRow.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import SwiftUI

/// A file row displaying upload progress, completion, or an error.
struct DocumentFileRow: View {

    /// The upload state displayed for a document.
    enum Status: Equatable {

        /// An upload in progress, with a fraction from zero to one.
        case uploading(Double)

        /// The document finished uploading successfully.
        case uploaded

        /// An error message displayed for the selected document.
        case failed(message: String)
    }

    /// The name of the selected file.
    let filename: String

    /// The current upload state displayed in the row.
    let status: Status

    /// The action that removes the selected document.
    let onRemove: () -> Void

    // MARK: - View

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(filename)
                    .typography(.bodyLarge)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(statusLabel)
                    .typography(.bodySmall)
                    .foregroundColor(statusTextColor)
                    .accessibilityValue(progressLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isUploading {
                removeButton
            }
        }
        .foregroundColor(.textPrimary)
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 16)
        .frame(minHeight: 76)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        }
        .dashedDocumentBorderOverlay(isVisible: isUploading)
        .accessibilityElement(children: .contain)
    }

    // MARK: - DocumentFileRow

    private var removeButton: some View {
        Button(action: onRemove) {
            SwiftUI.Image(uiImage: Image.iconTrash.makeImage(template: true))
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding(14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String.Localized.remove)
        .accessibilityValue(filename)
    }

    private var isUploading: Bool {
        if case .uploading = status {
            return true
        }
        return false
    }

    private var backgroundColor: Color {
        switch status {
        case .uploading:
            return .clear
        case .uploaded:
            return .surfaceSecondary
        case .failed:
            return .documentErrorBackground
        }
    }

    private var statusTextColor: Color {
        if case .failed = status {
            return .textCritical
        }
        return .textTertiary
    }

    private var progressLabel: String {
        guard case .uploading(let progress) = status else {
            return ""
        }
        return progress.formatted(.percent.precision(.fractionLength(0)))
    }

    private var statusLabel: String {
        switch status {
        case .uploading:
            return .Localized.uploadingDocument
        case .uploaded:
            return .Localized.documentUploaded
        case .failed(let message):
            return message
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .uploading(let progress):
            ZStack {
                Circle()
                    .stroke(Color.surfaceSecondary, lineWidth: 3)

                Circle()
                    .trim(from: 0, to: max(0.05, progress))
                    .stroke(Color.documentSuccess, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .animation(.linear(duration: 0.2), value: progress)
        case .uploaded:
            SwiftUI.Image(uiImage: Image.iconCheckCircle.makeImage(template: true))
                .resizable()
                .scaledToFit()
                .foregroundColor(.documentSuccess)
        case .failed:
            SwiftUI.Image(uiImage: Image.iconExclamationCircle.makeImage(template: true))
                .resizable()
                .scaledToFit()
                .foregroundColor(.surfaceCritical)
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Uploading", traits: .sizeThatFitsLayout) {
    DocumentFileRow(filename: "electricity_bill.pdf", status: .uploading(0.6), onRemove: {})
        .padding(20)
        .background(Color.surfacePrimary)
}

@available(iOS 17.0, *)
#Preview("Uploaded", traits: .sizeThatFitsLayout) {
    DocumentFileRow(filename: "electricity_bill.pdf", status: .uploaded, onRemove: {})
        .padding(20)
        .background(Color.surfacePrimary)
}

@available(iOS 17.0, *)
#Preview("Unsupported file type", traits: .sizeThatFitsLayout) {
    DocumentFileRow(
        filename: "electricity_bill.docx",
        status: .failed(message: "This file type isn’t supported. Upload a PDF, JPEG, or PNG file."),
        onRemove: {}
    )
    .padding(20)
    .background(Color.surfacePrimary)
}
#endif
