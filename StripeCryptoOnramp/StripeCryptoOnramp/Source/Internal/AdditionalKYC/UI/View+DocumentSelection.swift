//
//  View+DocumentSelection.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/1/26.
//

@_spi(STP) import StripeCore
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// The picker presentation, pending import, and error messages owned by a document collection screen.
struct DocumentSelectionState {

    /// A sheet presented while selecting a document or its category.
    enum Sheet: String, Identifiable {

        /// Select a document category.
        case subtype

        /// Select a file from Files or another document provider.
        case files

        /// Select an image from Photos.
        case photos

        // MARK: - Identifiable

        var id: String {
            rawValue
        }
    }

    /// A selected file that failed format or size validation.
    struct RejectedFile {

        /// The name displayed in the failed document row.
        let filename: String

        /// The localized validation error displayed with the file.
        let message: String
    }

    /// The currently presented category or file picker.
    var sheet: Sheet?

    /// Whether to offer Files and Photos in the source selection alert.
    var showsSourcePicker = false

    /// The selected file's available name while it is being copied from the picker.
    var importingFilename: String?

    /// The file to display with a format or size validation error, when present.
    var rejectedFile: RejectedFile?

    /// A localized error message to display below the document controls, when present.
    var errorMessage: String?

    fileprivate var importID = UUID()

    /// Creates picker state with an optional error from an earlier document submission.
    /// - Parameter errorMessage: The localized message to display when collection begins.
    init(errorMessage: String? = nil) {
        self.errorMessage = errorMessage
    }

    /// Clears previous selection errors and presents the requested file picker.
    /// - Parameter source: The system picker used to select the next file.
    mutating func beginSelection(_ source: DocumentPicker.Source) {
        importID = UUID()
        errorMessage = nil
        rejectedFile = nil

        switch source {
        case .files:
            sheet = .files
        case .photos:
            sheet = .photos
        }
    }

    /// Clears the pending import and prevents its callbacks from changing this screen.
    mutating func cancelImport() {
        importID = UUID()
        importingFilename = nil
    }
}

extension View {

    /// Presents the category picker, file source alert, and system file pickers for document collection.
    /// - Parameters:
    ///   - state: The screen's picker presentation, import progress, and error messages.
    ///   - configuration: The accepted file formats and size limit used during import.
    ///   - subtypes: The document categories available for selection.
    ///   - selectedSubtype: The screen's selected document category.
    ///   - appearance: The styling for the category picker.
    ///   - onSelectSource: Prepares the screen and presents the chosen picker using `state.beginSelection(_:)`.
    ///   - onSelectFile: Receives a successfully imported file to upload.
    /// - Returns: The view with document selection presentations attached.
    func documentSelection(
        state: Binding<DocumentSelectionState>,
        configuration: DocumentCollectionConfiguration,
        subtypes: [DocumentCollectionConfiguration.Subtype],
        selectedSubtype: Binding<DocumentCollectionConfiguration.Subtype?>,
        appearance: LinkAppearance,
        onSelectSource: @escaping (DocumentPicker.Source) -> Void,
        onSelectFile: @escaping (DocumentFile) -> Void
    ) -> some View {
        modifier(DocumentSelectionModifier(
            state: state,
            configuration: configuration,
            subtypes: subtypes,
            selectedSubtype: selectedSubtype,
            appearance: appearance,
            onSelectSource: onSelectSource,
            onSelectFile: onSelectFile
        ))
    }
}

private struct DocumentSelectionModifier: ViewModifier {
    @Binding var state: DocumentSelectionState
    let configuration: DocumentCollectionConfiguration
    let subtypes: [DocumentCollectionConfiguration.Subtype]
    @Binding var selectedSubtype: DocumentCollectionConfiguration.Subtype?
    let appearance: LinkAppearance
    let onSelectSource: (DocumentPicker.Source) -> Void
    let onSelectFile: (DocumentFile) -> Void

    // MARK: - ViewModifier

    func body(content: Content) -> some View {
        content
            .alert(String.Localized.uploadDocument, isPresented: $state.showsSourcePicker) {
                Button(String.Localized.chooseDocumentFile) {
                    onSelectSource(.files)
                }

                Button(String.Localized.chooseDocumentPhoto) {
                    onSelectSource(.photos)
                }

                Button(String.Localized.cancel, role: .cancel) {}
            }
            .sheet(item: $state.sheet) { sheet in
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
                    let operation = state.importID
                    DocumentPicker(source: sheet == .files ? .files : .photos, configuration: configuration, onBeginImport: { filename in
                        guard operation == state.importID else {
                            return
                        }

                        state.importingFilename = filename
                        state.sheet = nil
                    }, onCompletion: { result in
                        guard operation == state.importID else {
                            return
                        }

                        let filename = state.importingFilename ?? ""
                        state.importingFilename = nil
                        state.sheet = nil
                        switch result {
                        case .success(let file):
                            onSelectFile(file)
                        case .failure(let error):
                            if let collectionError = error as? DocumentCollectionError,
                               collectionError == .unsupportedFormat || collectionError == .fileTooLarge {
                                state.rejectedFile = .init(
                                    filename: filename.isEmpty ? "File" : filename,
                                    message: importErrorMessage(error)
                                )
                            } else {
                                state.errorMessage = importErrorMessage(error)
                            }
                        case nil:
                            break
                        }
                    })
                }
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
