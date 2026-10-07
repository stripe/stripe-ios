//
//  DocumentFile.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

import Foundation

/// Owns and represents a temporary copy of a selected file, including cleanup after cancellation or upload.
final class DocumentFile {

    /// The copied file’s URL in its temporary location.
    let url: URL

    /// The filename (last path component of `url`).
    var displayName: String {
        url.lastPathComponent
    }

    private init(url: URL) {
        self.url = url
    }

    /// Validates a selected file and copies it to a temporary location owned by the SDK.
    /// Call this while the picker's security scope or file-provider callback is still valid.
    /// - Parameters:
    ///   - source: The URL supplied by the file or photo picker.
    ///   - acceptedFormats: The allowed filename extensions without a leading period. Matching is case-insensitive, and `jpg` matches `jpeg`.
    ///   - maximumFileSize: The largest allowed file size, in bytes.
    /// - Returns: A document that owns the temporary copy and removes it when no longer needed.
    /// - Throws: A `DocumentCollectionError` if the file is empty, unreadable, unsupported, or too large; or a file-system error if the copy cannot be created.
    static func copy(from source: URL, acceptedFormats: [String], maximumFileSize: Int) throws -> DocumentFile {
        let accessed = source.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                source.stopAccessingSecurityScopedResource()
            }
        }

        let values = try source.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true, let size = values.fileSize, size > 0 else {
            throw DocumentCollectionError.unreadableFile
        }

        let fileExtension = source.pathExtension.normalizedDocumentFileExtension
        guard acceptedFormats.contains(where: { $0.normalizedDocumentFileExtension == fileExtension }) else {
            throw DocumentCollectionError.unsupportedFormat
        }

        guard size <= maximumFileSize else {
            throw DocumentCollectionError.fileTooLarge
        }

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("stripe-kyc-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = source.lastPathComponent.components(separatedBy: .controlCharacters).joined()
        let destination = directory.appendingPathComponent(name)

        do {
            try FileManager.default.copyItem(at: source, to: destination)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: destination.path)
            return .init(url: destination)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    func remove() {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    deinit {
        remove()
    }
}
