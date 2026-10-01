//
//  SourceOfFundsDocumentView.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/30/26.
//

@_spi(STP) import StripeCore
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// Edits the document category and uploaded files for one source of funds.
struct SourceOfFundsDocumentView: View {

    /// The formats, size limit, and instructions used for each selected file.
    let configuration: DocumentCollectionConfiguration

    /// The categories available for this source, excluding categories used by other sources.
    let subtypes: [DocumentCollectionConfiguration.Subtype]

    /// The appearance of the screen and controls.
    let appearance: LinkAppearance

    /// The draft files and their independent upload state.
    @ObservedObject var collection: DocumentCollectionModel

    /// Whether this screen was opened to change the category or documents of a previously added source of funds.
    let isEditing: Bool

    /// Saves the selected category and uploaded files, then returns to the summary.
    let onSave: (DocumentCollectionConfiguration.Subtype, [DocumentUploadModel.UploadedFile]) -> Void

    /// Closes the entire collection flow.
    let onClose: () -> Void

    @State private var selectedSubtype: DocumentCollectionConfiguration.Subtype?
    @State private var documentSelection = DocumentSelectionState()
    @Environment(\.colorScheme) private var inheritedColorScheme

    /// Creates an editor with the existing source's category, or the first available category, selected.
    /// - Parameters:
    ///   - configuration: File constraints and instructions supplied by the backend.
    ///   - subtypes: Categories not already used by another source.
    ///   - appearance: Styling for the screen and its controls.
    ///   - collection: The draft upload state, including any previously uploaded files.
    ///   - selectedSubtype: The category of an existing source, or `nil` for a new source.
    ///   - onSave: The action that commits the completed draft to the source summary.
    ///   - onClose: The action that dismisses the collection flow.
    init(
        configuration: DocumentCollectionConfiguration,
        subtypes: [DocumentCollectionConfiguration.Subtype],
        appearance: LinkAppearance,
        collection: DocumentCollectionModel,
        selectedSubtype: DocumentCollectionConfiguration.Subtype? = nil,
        onSave: @escaping (DocumentCollectionConfiguration.Subtype, [DocumentUploadModel.UploadedFile]) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.subtypes = subtypes
        self.appearance = appearance
        self.collection = collection
        self.isEditing = selectedSubtype != nil
        self.onSave = onSave
        self.onClose = onClose
        _selectedSubtype = State(initialValue: selectedSubtype ?? subtypes.first)
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(String.Localized.tellUsAboutYourSourceOfFunds)
                    .typography(.headingExtraLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 16) {
                    if let selectedSubtype {
                        DocumentSubtypeButton(title: .Localized.fundsSource, selection: selectedSubtype.label) {
                            documentSelection.sheet = .subtype
                        }
                    }

                    ForEach(collection.files) { file in
                        if let document = file.upload.document {
                            DocumentFileRow(filename: document.name.isEmpty ? "File" : document.name, status: rowStatus(for: document.status)) {
                                collection.remove(id: file.id)
                            }
                        }
                    }

                    if let importingFilename = documentSelection.importingFilename {
                        DocumentFileRow(filename: importingFilename.isEmpty ? "File" : importingFilename, status: .uploading(0), onRemove: {
                            documentSelection.cancelImport()
                        })
                    }

                    if let rejectedFile = documentSelection.rejectedFile {
                        DocumentFileRow(filename: rejectedFile.filename, status: .failed(message: rejectedFile.message), onRemove: {
                            documentSelection.rejectedFile = nil
                        })
                    }

                    UploadDocumentButton(detail: configuration.uploadHint) {
                        if configuration.allowsPhotoSelection {
                            documentSelection.showsSourcePicker = true
                        } else {
                            documentSelection.beginSelection(.files)
                        }
                    }
                    .disabled(selectedSubtype == nil || documentSelection.importingFilename != nil)

                    if let errorMessage = documentSelection.errorMessage {
                        InlineErrorMessageView(message: errorMessage)
                    }
                }

                DocumentInstructionsView(instructions: configuration.instructions)
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()

                PrimaryActionButton(title: saveTitle, appearance: appearance, action: save, isEnabled: canSave)
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
        .toolbar {
            CloseToolbarItem(action: close)
        }
        .accessibilityAction(.escape, close)
        .documentSelection(
            state: $documentSelection,
            configuration: configuration,
            subtypes: subtypes,
            selectedSubtype: $selectedSubtype,
            appearance: appearance,
            onSelectSource: {
                documentSelection.beginSelection($0)
            },
            onSelectFile: collection.add
        )
    }

    private var canSave: Bool {
        selectedSubtype != nil && collection.isComplete && (isEditing || !collection.files.isEmpty) && documentSelection.importingFilename == nil && documentSelection.rejectedFile == nil
    }

    private var saveTitle: String {
        if isEditing {
            return UIButton.doneButtonTitle
        }
        return collection.files.isEmpty ? .Localized.addDocuments : .Localized.addDocuments(count: collection.files.count)
    }

    private func save() {
        guard canSave, let selectedSubtype else {
            return
        }
        onSave(selectedSubtype, collection.uploadedFiles)
    }

    private func close() {
        documentSelection.cancelImport()
        collection.cancel()
        onClose()
    }

    private func rowStatus(for status: DocumentUploadModel.Status) -> DocumentFileRow.Status {
        switch status {
        case .uploading(let progress):
            return .uploading(progress)
        case .uploaded:
            return .uploaded
        case .failed:
            return .failed(message: .Localized.documentUploadFailed)
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Source of funds documents") {
    NavigationView {
        SourceOfFundsDocumentView(
            configuration: .sourceOfFundsPreview,
            subtypes: DocumentCollectionConfiguration.sourceOfFundsPreview.acceptedSubtypes,
            appearance: .previewLinkAppearance,
            collection: .init(uploader: SourceOfFundsPreviewUploader(), uploadedFiles: [
                .init(name: "payslip.pdf", fileID: "file_preview"),
            ]),
            onSave: { _, _ in },
            onClose: {}
        )
    }
}

private struct SourceOfFundsPreviewUploader: DocumentUploading {

    // MARK: - DocumentUploading

    func upload(_ file: DocumentFile, progress: @escaping @Sendable (Double) -> Void) async throws -> String {
        "file_preview"
    }
}
#endif
