//
//  DocumentCollectionModel.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/30/26.
//

import Combine
import Foundation

/// Owns independent uploads for the files being collected for one document category.
@MainActor
final class DocumentCollectionModel: ObservableObject {

    /// A file with stable identity while its upload progresses.
    struct File: Identifiable {

        // MARK: - Identifiable

        let id = UUID()

        // MARK: - File

        /// The upload state for this file.
        let upload: DocumentUploadModel
    }

    /// The files in display order, including pending and failed uploads.
    @Published private(set) var files: [File] = []

    /// Whether another file can be added to this document category.
    var canAddFile: Bool {
        isActive && files.count < maximumFileCount
    }

    /// Whether every remaining file has finished uploading successfully.
    var isComplete: Bool {
        files.allSatisfy { $0.upload.uploadedFileID != nil }
    }

    /// Successfully uploaded files, ready to save in a source summary.
    var uploadedFiles: [DocumentUploadModel.UploadedFile] {
        files.compactMap { $0.upload.uploadedFile }
    }

    private let uploader: DocumentUploading
    private let maximumFileCount: Int
    private var observations: [UUID: AnyCancellable] = [:]
    private var isActive = true

    /// Creates a draft collection, optionally restoring files already added to a source.
    /// - Parameters:
    ///   - uploader: The service used for new uploads.
    ///   - uploadedFiles: Existing uploaded documents to edit without uploading them again.
    ///   - maximumFileCount: The maximum number of files for this document category, including restored files.
    init(uploader: DocumentUploading, uploadedFiles: [DocumentUploadModel.UploadedFile] = [], maximumFileCount: Int) {
        self.uploader = uploader
        self.maximumFileCount = maximumFileCount
        for file in uploadedFiles {
            append(DocumentUploadModel(uploader: uploader, uploadedFile: file))
        }
    }

    /// Starts a new upload without disturbing other files in the collection.
    /// - Parameter file: The temporary document whose ownership transfers to its upload model.
    func add(_ file: DocumentFile) {
        guard canAddFile else {
            file.remove()
            return
        }

        let upload = DocumentUploadModel(uploader: uploader)
        upload.select(file)
        append(upload)
    }

    /// Removes one file and cancels only its upload.
    /// - Parameter id: The collection identifier of the file to remove.
    func remove(id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else {
            return
        }

        let file = files.remove(at: index)
        observations[file.id] = nil
        file.upload.cancel()
    }

    /// Ends collection and prevents late picker callbacks from starting new uploads.
    func cancel() {
        isActive = false
        observations.removeAll()
        files.forEach { $0.upload.cancel() }
        files = []
    }

    private func append(_ upload: DocumentUploadModel) {
        let file = File(upload: upload)
        observations[file.id] = upload.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
        files.append(file)
    }
}
