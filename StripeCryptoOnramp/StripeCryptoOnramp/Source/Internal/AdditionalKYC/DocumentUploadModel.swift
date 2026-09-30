//
//  DocumentUploadModel.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

import Combine
import Foundation
@_spi(STP) import StripeCore

/// Protocol representing a type capable of uploading a document. Used for mocking upload behavior in tests.
protocol DocumentUploading {

    /// Uploads a document and returns its Files API identifier.
    /// - Parameters:
    ///   - file: The temporary document to upload. The caller retains ownership of its local copy.
    ///   - progress: Reports the completed fraction of the transfer, from 0 to 1.
    /// - Returns: The uploaded file's identifier.
    /// - Throws: An error if the upload cannot complete.
    func upload(_ file: DocumentFile, progress: @escaping @Sendable (Double) -> Void) async throws -> String
}

/// Uploads additional-KYC documents using the current Link session.
struct KYCDocumentUploader: DocumentUploading {

    /// The client that sends the file to the Files API.
    let apiClient: STPAPIClient

    /// The Link session key used to authorize the upload.
    let linkSessionKey: String

    // MARK: - DocumentUploading

    func upload(_ file: DocumentFile, progress: @escaping @Sendable (Double) -> Void) async throws -> String {
        guard !linkSessionKey.isEmpty else {
            throw DocumentCollectionError.missingLinkSessionKey
        }
        return try await apiClient.uploadFile(
            at: file.url,
            purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue,
            authorizationSecret: linkSessionKey,
            progress: progress
        ).id
    }
}

/// Upload state for one file.
@MainActor
final class DocumentUploadModel: ObservableObject {

    /// The current transfer state of the selected document.
    enum Status: Hashable {

        /// The file is being uploaded. The associated value is progress from 0 to 1.
        case uploading(progress: Double)

        /// The upload completed. The associated value is the Files API identifier.
        case uploaded(fileID: String)

        /// The upload failed, and the retained file can be retried.
        case failed
    }

    /// The selected file's display information and upload state.
    struct Document: Equatable {

        /// The selected file's name.
        let name: String

        /// The file's current upload state.
        var status: Status
    }

    /// The selected document, or `nil` before selection and after removal.
    @Published private(set) var document: Document?

    private let uploader: DocumentUploading
    private var file: DocumentFile?
    private var task: Task<Void, Never>?
    private var isActive = true

    // Each attempt gets a new ID. Callbacks from an older attempt are ignored after removal or retry.
    private var operationID: UUID?


    /// The Files API identifier after a successful upload, or `nil` otherwise.
    var uploadedFileID: String? {
        guard case .uploaded(fileID: let fileID) = document?.status else {
            return nil
        }
        return fileID
    }

    /// Creates upload state using the supplied uploader.
    /// - Parameter uploader: The instance that uploads selected documents.
    init(uploader: DocumentUploading) {
        self.uploader = uploader
    }

    /// Replaces the current selection and starts uploading the new file.
    /// - Parameter file: The temporary document to select. The model takes ownership of it.
    func select(_ file: DocumentFile) {
        guard isActive else {
            return
        }
        remove()
        self.file = file
        upload(file)
    }

    /// Retries the last failed upload using the retained file.
    func retry() {
        guard case .failed = document?.status, let file else {
            return
        }
        upload(file)
    }

    /// Removes the selection and cancels its upload, if one is running.
    func remove() {
        operationID = nil
        task?.cancel()
        task = nil
        file = nil
        document = nil
    }

    /// Ends this collection permanently so a late file-provider callback cannot start another upload.
    func cancel() {
        isActive = false
        remove()
    }

    /// Starts or retries a transfer.
    private func upload(_ file: DocumentFile) {
        let id = UUID()
        operationID = id
        document = .init(name: file.displayName, status: .uploading(progress: 0))
        let uploader = uploader
        task = Task { [weak self] in
            do {
                let fileID = try await uploader.upload(file) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        guard let self, self.operationID == id, case .uploading = self.document?.status else {
                            return
                        }
                        self.document?.status = .uploading(progress: min(1, max(0, progress)))
                    }
                }
                guard !Task.isCancelled, let self, self.operationID == id else {
                    return
                }
                self.document?.status = .uploaded(fileID: fileID)
                self.file = nil
                self.task = nil
                file.remove()
            } catch {
                guard !Task.isCancelled, let self, self.operationID == id else {
                    return
                }
                self.document?.status = .failed
                self.task = nil
            }
        }
    }

    deinit {
        task?.cancel()
    }

    #if DEBUG
    // MARK: - Preview support

    /// Supplies static preview content without making a Files API request.
    /// - Parameter document: The document state to display in the preview.
    /// - Returns: A model configured with the supplied state and a no-network uploader.
    static func preview(document: Document? = nil) -> DocumentUploadModel {
        let model = DocumentUploadModel(uploader: PreviewUploader())
        model.document = document
        return model
    }

    private struct PreviewUploader: DocumentUploading {

        // MARK: - DocumentUploading

        func upload(_ file: DocumentFile, progress: @escaping @Sendable (Double) -> Void) async throws -> String {
            progress(1)
            return "file_preview"
        }
    }
    #endif
}
