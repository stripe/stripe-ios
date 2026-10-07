//
//  DocumentPicker.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

import PhotosUI
@_spi(STP) import StripeCore
import SwiftUI
import UniformTypeIdentifiers

/// Imports existing files or photos, or captures a new photo with the system camera.
struct DocumentPicker: UIViewControllerRepresentable {

    /// The system interface used to select or capture a document.
    enum Source {

        /// Select a file from Files or another document provider.
        case files

        /// Select an existing image from Photos.
        case photos

        /// Take a new photo with the camera.
        case camera
    }

    /// The location from which to select the document.
    let source: Source

    /// The accepted file formats and per-file size limit used during import.
    let configuration: DocumentCollectionConfiguration

    /// Called with the file's name before it is copied or the captured photo is saved.
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
        case .camera:
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = [UTType.image.identifier]
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
    final class Coordinator: NSObject, UIDocumentPickerDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

        // MARK: - UIImagePickerControllerDelegate

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCompletion(nil)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage else {
                parent.onCompletion(.failure(DocumentCollectionError.unreadableFile))
                return
            }

            let configuration = parent.configuration
            guard let format = configuration.cameraImageFormat else {
                parent.onCompletion(.failure(DocumentCollectionError.unsupportedFormat))
                return
            }

            let filename = format == .jpeg ? "photo.jpg" : "photo.png"
            parent.onBeginImport(filename)

            DispatchQueue.global(qos: .userInitiated).async {
                let result = Result {
                    var imageToEncode = image
                    if format == .png && image.imageOrientation != .up {
                        // PNG encoding does not preserve orientation metadata, so redraw the image rotated if needed.
                        let rendererFormat = UIGraphicsImageRendererFormat()
                        rendererFormat.scale = image.scale
                        imageToEncode = UIGraphicsImageRenderer(size: image.size, format: rendererFormat).image { _ in
                            image.draw(at: .zero)
                        }
                    }

                    let imageData = format == .jpeg ? imageToEncode.jpegDataAndDimensions(maxBytes: configuration.maximumFileSize).imageData : imageToEncode.pngData()

                    guard let data = imageData else {
                        throw DocumentCollectionError.unreadableFile
                    }

                    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("stripe-kyc-camera-\(UUID().uuidString)", isDirectory: true)

                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

                    defer {
                        try? FileManager.default.removeItem(at: directory)
                    }

                    let url = directory.appendingPathComponent(filename)
                    try data.write(to: url, options: .completeFileProtectionUntilFirstUserAuthentication)
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
