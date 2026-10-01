//
//  SourceOfFundsView.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/30/26.
//

@_spi(STP) import StripeCore
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// Displays the source summary and submits the collected documents for review.
struct SourceOfFundsView: View {

    /// The appearance of the summary and primary action.
    let appearance: LinkAppearance

    /// The uploaded documents grouped by source.
    @ObservedObject var model: SourceOfFundsModel

    /// A localized error message describing a problem with a previously submitted document, when present.
    var initialErrorMessage: String?

    /// Opens the editor for an existing source, or a new one when `nil`.
    let onEdit: (SourceOfFundsModel.Source?) -> Void

    /// Submits the grouped documents, throwing if the request fails.
    let onSubmit: ([FulfillKYCRequirementsRequest.Document]) async throws -> Void

    /// Closes the entire collection flow.
    let onClose: () -> Void

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var submissionTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var inheritedColorScheme

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(String.Localized.tellUsAboutYourSourceOfFunds)
                    .typography(.headingExtraLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(String.Localized.sourceOfFundsDocumentsExplanation)
                    .typography(.bodyMedium)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SourceOfFundsDocumentsView(sources: model.sources.map { source in
                    .init(id: source.id, name: source.subtype.label, filenames: source.files.map(\.name))
                }, onSelection: { selection in
                    switch selection {
                    case .addDocuments:
                        onEdit(nil)
                    case .source(let id):
                        onEdit(model.sources.first { $0.id == id })
                    }
                }, canAddDocuments: model.canAddSource)
                .disabled(isSubmitting)

                if let message = errorMessage ?? (model.sources.isEmpty ? initialErrorMessage : nil) {
                    InlineErrorMessageView(message: message)
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()

                PrimaryActionButton(title: .Localized.submit, appearance: appearance, action: submit, isEnabled: model.canSubmit, isProcessing: isSubmitting)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .background(Color.surfacePrimary)
            }
        }
        .background(Color.surfacePrimary.ignoresSafeArea())
        .environment(\.colorScheme, appearance.colorScheme ?? inheritedColorScheme)
        .preferredColorScheme(appearance.colorScheme)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isSubmitting)
        .toolbar {
            CloseToolbarItem(action: close)
        }
        .accessibilityAction(.escape, close)
        .onDisappear {
            submissionTask?.cancel()
        }
    }

    private func submit() {
        guard model.canSubmit, !isSubmitting else {
            return
        }

        isSubmitting = true
        errorMessage = nil
        submissionTask = Task { @MainActor in
            defer {
                isSubmitting = false
                submissionTask = nil
            }
            do {
                try await onSubmit(model.documents)
            } catch {
                if !Task.isCancelled {
                    errorMessage = .Localized.tryAgainLater
                }
            }
        }
    }

    private func close() {
        guard !isSubmitting else {
            return
        }

        onClose()
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Source of funds summary") {
    NavigationView {
        SourceOfFundsView(appearance: .previewLinkAppearance, model: .init(configuration: .sourceOfFundsPreview), onEdit: { _ in }, onSubmit: { _ in }, onClose: {})
    }
}
#endif
