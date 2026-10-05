//
//  DocumentCollectionConfiguration.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

import Foundation
import UniformTypeIdentifiers

/// Presentation and validation inputs for document collection.
struct DocumentCollectionConfiguration {

    /// A selectable document category.
    struct Subtype: Identifiable, Equatable {

        // MARK: - Identifiable

        let id: String

        // MARK: - Subtype

        /// The name displayed for this document category.
        let label: String

        /// Examples or details displayed below the category's label.
        let description: String?
    }

    /// The selectable document categories, in display order.
    let acceptedSubtypes: [Subtype]

    /// The file extensions allowed for selected documents.
    let acceptedFormats: [String]

    /// Document instruction bullets, in display order.
    let instructions: [String]

    /// The maximum allowed size of each individual file, in bytes.
    let maximumFileSize: Int

    /// Guidance describing the accepted formats and file size limit.
    let uploadHint: String

    /// The minimum number of distinct document categories required for submission.
    var minimumDocumentTypes = 1

    /// The maximum number of distinct document categories that may be submitted.
    var maximumDocumentTypes = 1

    /// Maps the file extensions to `UTType`s for use in filtering with Files.
    var documentPickerContentTypes: [UTType] {
        acceptedFormats.map { format in
            guard let type = UTType(filenameExtension: format.normalizedDocumentFileExtension), !type.isDynamic else {
                return .data
            }
            return type
        }
    }

    /// Whether to offer access to the photo library, based on document type (e.g. don't allow picking from photo library if we require PDF).
    var allowsPhotoSelection: Bool {
        documentPickerContentTypes.contains { $0.conforms(to: .image) }
    }

    /// User-readable file size limit.
    var maximumFileSizeLabel: String {
        ByteCountFormatter.string(fromByteCount: Int64(maximumFileSize), countStyle: .file)
    }
}

extension DocumentCollectionConfiguration {

    /// Adapts a requirement that can be fulfilled with one proof-of-address file.
    /// - Parameter requirement: The document requirements returned by the backend.
    init(proofOfAddress requirement: AdditionalKYCDocumentRequirement) throws {
        guard requirement.minDocumentTypes <= 1 else {
            throw DocumentCollectionError.unsupportedRequirement
        }
        try self.init(document: requirement)
    }

    /// Adapts document requirements, including bounds on the number of distinct categories.
    /// - Parameter requirement: The document requirements returned by the backend.
    /// - Throws: `DocumentCollectionError.unsupportedRequirement` when the requirements cannot be collected.
    init(document requirement: AdditionalKYCDocumentRequirement) throws {
        guard requirement.minDocumentTypes >= 0,
              requirement.maxDocumentTypes >= max(1, requirement.minDocumentTypes),
              requirement.minDocumentTypes <= requirement.acceptedSubtypes.count,
              requirement.maxFileSizeBytes > 0,
              !requirement.acceptedSubtypes.isEmpty,
              requirement.acceptedSubtypes.allSatisfy({ !$0.id.isEmpty }),
              Set(requirement.acceptedSubtypes.map(\.id)).count == requirement.acceptedSubtypes.count else {
            throw DocumentCollectionError.unsupportedRequirement
        }

        let formats = requirement.acceptedFormats.map(\.normalizedDocumentFileExtension)

        guard !formats.isEmpty else {
            throw DocumentCollectionError.unsupportedRequirement
        }

        self.init(
            acceptedSubtypes: requirement.acceptedSubtypes.map { subtype in
                .init(id: subtype.id, label: subtype.label, description: subtype.description)
            },
            acceptedFormats: formats.reduce(into: []) { result, format in
                if !result.contains(format) {
                    result.append(format)
                }
            },
            instructions: requirement.instructions,
            maximumFileSize: requirement.maxFileSizeBytes,
            uploadHint: requirement.fileRequirements,
            minimumDocumentTypes: requirement.minDocumentTypes,
            maximumDocumentTypes: requirement.maxDocumentTypes
        )
    }
}

#if DEBUG
extension DocumentCollectionConfiguration {

    /// An example proof-of-address configuration with sample text for previews.
    static var preview: Self {
        .init(acceptedSubtypes: [
            .init(id: "id_documents", label: "ID documents", description: "ID card, passport, residence permit, or driver's license."),
            .init(id: "government_organization_documents", label: "Government organization documents", description: "Statement, voter registration, or tax bill."),
            .init(id: "utility_provider", label: "Utility provider", description: "Telecom or utility bill."),
            .init(id: "bank", label: "Bank", description: "Bank statement or bank letter."),
            .init(id: "lease_agreement", label: "Lease agreement", description: nil),
        ], acceptedFormats: ["pdf", "jpeg", "png"], instructions: [
            "Documents must include your full name and address.",
            "ID documents must be valid and in date.",
            "Other documents must have been issued in the last 12 months.",
            "For physical documents, all four corners must be visible.",
            "For digital documents, upload the original PDF; screenshots aren't accepted.",
        ], maximumFileSize: 50_000_000, uploadHint: "PDF, JPEG/JPG, or PNG, up to 50 MB per file.")
    }

    /// An example source-of-funds configuration with sample text for previews.
    static var sourceOfFundsPreview: Self {
        .init(acceptedSubtypes: [
            .init(id: "salary", label: "Salary", description: "Recent payslips from your employer"),
            .init(id: "company_profits", label: "Company profits", description: "Dividend distribution statements"),
        ], acceptedFormats: ["pdf", "jpeg", "png", "docx", "xlsx", "csv", "txt"], instructions: [
            "Documents must include your name and a balance or financial value.",
            "Bank statements must be original PDFs issued through online banking; screenshots aren't accepted.",
        ], maximumFileSize: 5_000_000, uploadHint: "PDF, JPEG/JPG, PNG, DOCX, XLSX, CSV, or TXT, up to 5 MB per file.", maximumDocumentTypes: 2)
    }
}
#endif
