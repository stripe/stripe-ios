//
//  DocumentPicker.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Imports existing files or photos without requesting camera access.
struct DocumentPicker: UIViewControllerRepresentable {

    /// The system picker used to select an existing document.
    enum Source {

        /// Select a file from Files or another document provider.
        case files

        /// Select an existing image from Photos.
        case photos
    }

    /// The location from which to select the document.
    let source: Source

    /// The accepted file formats and per-file size limit used during import.
    let configuration: DocumentCollectionConfiguration

    /// Called with the selected file's available name before the picker-owned file is copied.
    let onBeginImport: (String) -> Void

    /// Receives the imported file or an error; a `nil` result indicates the picker was canceled.
    let onCompletion: (Result<DocumentFile, Error>?) -> Void

    // MARK: - UIViewControllerRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        switch source {
        case .files:
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: configuration.documentPickerContentTypes, asCopy: true)
            picker.allowsMultipleSelection = false
            picker.delegate = context.coordinator
            return picker
        case .photos:
            var settings = PHPickerConfiguration()
            settings.filter = .images
            settings.selectionLimit = 1
            settings.preferredAssetRepresentationMode = .compatible
            let picker = PHPickerViewController(configuration: settings)
            picker.delegate = context.coordinator
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Picker settings are fixed for this presentation.
    }

    // MARK: - Coordinator

    /// Routes system picker selections and cancellation back to document collection.
    final class Coordinator: NSObject, UIDocumentPickerDelegate, PHPickerViewControllerDelegate {
        private let parent: DocumentPicker

        /// Creates a delegate that delivers picker events to the supplied view.
        /// - Parameter parent: The representable whose callbacks receive picker events.
        init(parent: DocumentPicker) {
            self.parent = parent
        }

        // MARK: - UIDocumentPickerDelegate

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCompletion(nil)
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.onCompletion(nil)
                return
            }

            parent.onBeginImport(url.lastPathComponent)
            let configuration = parent.configuration

            DispatchQueue.global(qos: .userInitiated).async {
                let result = Result {
                    try DocumentFile.copy(from: url, acceptedFormats: configuration.acceptedFormats, maximumFileSize: configuration.maximumFileSize)
                }

                DispatchQueue.main.async {
                    self.parent.onCompletion(result)
                }
            }
        }

        // MARK: - PHPickerViewControllerDelegate

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                parent.onCompletion(nil)
                return
            }

            parent.onBeginImport(provider.suggestedName ?? "")
            let configuration = parent.configuration
            let acceptedImageTypes = configuration.documentPickerContentTypes.filter { $0.conforms(to: .image) }

            guard let identifier = provider.registeredTypeIdentifiers.first(where: { identifier in
                guard let type = UTType(identifier) else {
                    return false
                }
                return acceptedImageTypes.contains { type.conforms(to: $0) }
            }) else {
                parent.onCompletion(.failure(DocumentCollectionError.unsupportedFormat))
                return
            }

            provider.loadFileRepresentation(forTypeIdentifier: identifier) { url, error in

                // Provider URLs are temporary and must be copied before this callback returns.
                let result: Result<DocumentFile, Error> = Result {
                    if let error {
                        throw error
                    }
                    guard let url else {
                        throw DocumentCollectionError.unreadableFile
                    }
                    return try DocumentFile.copy(from: url, acceptedFormats: configuration.acceptedFormats, maximumFileSize: configuration.maximumFileSize)
                }

                DispatchQueue.main.async {
                    self.parent.onCompletion(result)
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Files picker") {
    DocumentPicker(source: .files, configuration: .preview, onBeginImport: { _ in }, onCompletion: { _ in })
}

@available(iOS 17.0, *)
#Preview("Photos picker") {
    DocumentPicker(source: .photos, configuration: .preview, onBeginImport: { _ in }, onCompletion: { _ in })
}
#endif
