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
    private enum Sheet: String, Identifiable {
        case subtype
        case files
        case photos

        // MARK: - Identifiable

        var id: String {
            rawValue
        }
    }

    private struct RejectedFile {
        let name: String
        let message: String
    }

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
    @State private var activeSheet: Sheet?
    @State private var showsSourcePicker = false
    @State private var importingFilename: String?
    @State private var rejectedFile: RejectedFile?
    @State private var errorMessage: String?
    @State private var importID = UUID()
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
                            activeSheet = .subtype
                        }
                    }

                    ForEach(collection.files) { file in
                        if let document = file.upload.document {
                            DocumentFileRow(filename: document.name.isEmpty ? "File" : document.name, status: rowStatus(for: document.status)) {
                                collection.remove(id: file.id)
                            }
                        }
                    }

                    if let importingFilename {
                        DocumentFileRow(filename: importingFilename.isEmpty ? "File" : importingFilename, status: .uploading(0), onRemove: {
                            importID = UUID()
                            self.importingFilename = nil
                        })
                    }

                    if let rejectedFile {
                        DocumentFileRow(filename: rejectedFile.name, status: .failed(message: rejectedFile.message), onRemove: {
                            self.rejectedFile = nil
                        })
                    }

                    UploadDocumentButton(detail: configuration.uploadHint) {
                        if configuration.allowsPhotoSelection {
                            showsSourcePicker = true
                        } else {
                            beginSelection(.files)
                        }
                    }
                    .disabled(selectedSubtype == nil || importingFilename != nil)

                    if let errorMessage {
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
        .alert(String.Localized.uploadDocument, isPresented: $showsSourcePicker) {
            Button(String.Localized.chooseDocumentFile) {
                beginSelection(.files)
            }
            Button(String.Localized.chooseDocumentPhoto) {
                beginSelection(.photos)
            }
            Button(String.Localized.cancel, role: .cancel) {}
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .subtype:
                NavigationView {
                    DocumentSubtypePickerView(title: .Localized.documentType, subtypes: subtypes, selectedID: selectedSubtype?.id, appearance: appearance) {
                        selectedSubtype = $0
                    }
                }
                .navigationViewStyle(.stack)
                .preferredColorScheme(appearance.colorScheme)
            case .files, .photos:
                let operation = importID
                DocumentPicker(source: sheet == .files ? .files : .photos, configuration: configuration, onBeginImport: { filename in
                    guard operation == importID else {
                        return
                    }
                    importingFilename = filename
                    activeSheet = nil
                }, onCompletion: { result in
                    guard operation == importID else {
                        return
                    }
                    let filename = importingFilename ?? ""
                    importingFilename = nil
                    activeSheet = nil
                    switch result {
                    case .success(let file):
                        collection.add(file)
                    case .failure(let error):
                        if let error = error as? DocumentCollectionError,
                           error == .unsupportedFormat || error == .fileTooLarge {
                            rejectedFile = .init(name: filename.isEmpty ? "File" : filename, message: importErrorMessage(error))
                        } else {
                            errorMessage = importErrorMessage(error)
                        }
                    case nil:
                        break
                    }
                })
            }
        }
    }

    private var canSave: Bool {
        selectedSubtype != nil && collection.isComplete && (isEditing || !collection.files.isEmpty) && importingFilename == nil && rejectedFile == nil
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
        importID = UUID()
        collection.cancel()
        onClose()
    }

    private func beginSelection(_ sheet: Sheet) {
        importID = UUID()
        rejectedFile = nil
        errorMessage = nil
        activeSheet = sheet
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

    private func importErrorMessage(_ error: Error) -> String {
        switch error as? DocumentCollectionError {
        case .unsupportedFormat:
            return .Localized.unsupportedDocumentFormat(formats: configuration.acceptedFormats)
        case .fileTooLarge:
            return .Localized.documentTooLarge(size: configuration.maximumFileSizeLabel)
        default:
            return .Localized.unableToOpenDocument
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
