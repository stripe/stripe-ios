//
//  DocumentFileTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 9/16/26.
//

@testable import StripeCryptoOnramp
import UniformTypeIdentifiers
import XCTest

final class DocumentFileTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testSupportedFormatsUseSpecificPickerTypesAndPreserveFiles() throws {
        let examples: [(String, String, String)] = [
            ("pdf", "pdf", "com.adobe.pdf"),
            ("jpg", "JPEG", "public.jpeg"),
            ("JPEG", "jpg", "public.jpeg"),
            ("png", "png", "public.png"),
            ("DOCX", "docx", "org.openxmlformats.wordprocessingml.document"),
            ("xlsx", "xlsx", "org.openxmlformats.spreadsheetml.sheet"),
            ("csv", "csv", "public.comma-separated-values-text"),
            ("txt", "txt", "public.plain-text"),
            ("heic", "heic", "public.heic"),
        ]

        let bytes = Data("Document contents are not inspected".utf8)
        for (extensionName, acceptedExtension, typeIdentifier) in examples {
            let configuration = DocumentCollectionConfiguration(
                acceptedSubtypes: [],
                acceptedFormats: [acceptedExtension],
                instructions: [],
                maximumFileSize: bytes.count,
                uploadHint: "Document requirements"
            )

            XCTAssertEqual(configuration.documentPickerContentTypes.map(\.identifier), [typeIdentifier])
            let source = directory.appendingPathComponent("document.\(extensionName)")
            try bytes.write(to: source)
            var file: DocumentFile? = try DocumentFile.copy(from: source, acceptedFormats: configuration.acceptedFormats, maximumFileSize: bytes.count)
            let copiedURL = try XCTUnwrap(file?.url)
            XCTAssertEqual(file?.displayName, source.lastPathComponent)
            XCTAssertEqual(try Data(contentsOf: copiedURL), bytes)
            file = nil
            XCTAssertFalse(FileManager.default.fileExists(atPath: copiedURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        }
    }

    func testFileOneByteOverLimitIsRejected() throws {
        let source = directory.appendingPathComponent("document.pdf")
        let data = Data("%PDF-1.7".utf8)
        try data.write(to: source)
        XCTAssertThrowsError(try DocumentFile.copy(from: source, acceptedFormats: ["pdf"], maximumFileSize: data.count - 1)) {
            XCTAssertEqual($0 as? DocumentCollectionError, .fileTooLarge)
        }
    }

    func testDisallowedFormatIsRejected() throws {
        let source = directory.appendingPathComponent("document.pdf")
        try Data("%PDF-1.7".utf8).write(to: source)
        XCTAssertThrowsError(try DocumentFile.copy(from: source, acceptedFormats: ["png"], maximumFileSize: 100)) {
            XCTAssertEqual($0 as? DocumentCollectionError, .unsupportedFormat)
        }
    }

    func testConfigurationUsesRequirementMetadataAndPreservesUnknownFormats() throws {
        let requirement = AdditionalKYCDocumentRequirement(
            acceptedSubtypes: [
                .init(id: "new_category", label: "A backend label", description: "Examples supplied by the backend"),
                .init(id: "another_category", label: "Another backend label", description: nil),
            ],
            acceptedFormats: ["PDF", "future-format", "JPG", "jpeg"],
            maxFileSizeBytes: 12_000_000,
            minDocumentTypes: 1,
            maxDocumentTypes: 2,
            maxFilesPerDocumentType: 3,
            fileRequirements: "PDF, future-format, or JPEG up to 12 MB",
            instructions: ["First instruction", "Second instruction"]
        )

        let configuration = try DocumentCollectionConfiguration(proofOfAddress: requirement)
        XCTAssertEqual(configuration.acceptedSubtypes, [
            .init(id: "new_category", label: "A backend label", description: "Examples supplied by the backend"),
            .init(id: "another_category", label: "Another backend label", description: nil),
        ])

        XCTAssertEqual(configuration.acceptedFormats, ["pdf", "future-format", "jpeg"])
        XCTAssertEqual(configuration.instructions, requirement.instructions)
        XCTAssertEqual(configuration.maximumFileSize, 12_000_000)
        XCTAssertEqual(configuration.maximumFilesPerDocumentType, 3)
        XCTAssertEqual(configuration.uploadHint, requirement.fileRequirements)
    }

    func testUnrecognizedExtensionUsesPickerFallbackAndValidatesAllowlist() throws {
        let bytes = Data("Arbitrary document contents".utf8)
        let requirement = AdditionalKYCDocumentRequirement(
            acceptedSubtypes: [.init(id: "document", label: "Document", description: nil)],
            acceptedFormats: ["future-format"],
            maxFileSizeBytes: bytes.count,
            minDocumentTypes: 1,
            maxDocumentTypes: 1,
            maxFilesPerDocumentType: nil,
            fileRequirements: "Guidance for a new document format",
            instructions: []
        )

        let configuration = try DocumentCollectionConfiguration(proofOfAddress: requirement)
        XCTAssertEqual(configuration.acceptedFormats, ["future-format"])
        XCTAssertEqual(configuration.maximumFilesPerDocumentType, 10)
        XCTAssertEqual(configuration.documentPickerContentTypes, [.data])
        XCTAssertFalse(configuration.allowsPhotoSelection)

        let source = directory.appendingPathComponent("document.future-format")
        try bytes.write(to: source)
        let file = try DocumentFile.copy(from: source, acceptedFormats: configuration.acceptedFormats, maximumFileSize: configuration.maximumFileSize)
        XCTAssertEqual(try Data(contentsOf: file.url), bytes)

        let unlistedFileURL = directory.appendingPathComponent("document.pdf")
        try bytes.write(to: unlistedFileURL)
        XCTAssertThrowsError(try DocumentFile.copy(from: unlistedFileURL, acceptedFormats: configuration.acceptedFormats, maximumFileSize: configuration.maximumFileSize)) {
            XCTAssertEqual($0 as? DocumentCollectionError, .unsupportedFormat)
        }
    }

    func testPhotoSelectionRequiresAnAcceptedImageFormat() {
        for (formats, expectedAllowsPhotoSelection): ([String], Bool) in [
            ([], false),
            (["pdf"], false),
            (["docx", "xlsx", "csv", "txt"], false),
            (["future-format"], false),
            (["pdf", "JPEG"], true),
            (["png"], true),
            (["heic"], true),
        ] {
            let configuration = DocumentCollectionConfiguration(
                acceptedSubtypes: [],
                acceptedFormats: formats,
                instructions: [],
                maximumFileSize: 50_000_000,
                uploadHint: "Document requirements"
            )
            XCTAssertEqual(configuration.allowsPhotoSelection, expectedAllowsPhotoSelection)
        }
    }

    func testLocalizedUploadHintDoesNotReplaceStructuredValidation() throws {
        let sourceFileURL = directory.appendingPathComponent("document.png")
        try Data("Arbitrary document bytes".utf8).write(to: sourceFileURL)
        for fileRequirements in ["A localized hint supplied by the backend", ""] {
            let requirement = AdditionalKYCDocumentRequirement(
                acceptedSubtypes: [.init(id: "utility_bill", label: "Utility bill", description: nil)],
                acceptedFormats: ["pdf"],
                maxFileSizeBytes: 50_000_000,
                minDocumentTypes: 1,
                maxDocumentTypes: 1,
                maxFilesPerDocumentType: nil,
                fileRequirements: fileRequirements,
                instructions: []
            )
            let configuration = try DocumentCollectionConfiguration(proofOfAddress: requirement)
            XCTAssertEqual(configuration.uploadHint, fileRequirements)
            XCTAssertEqual(configuration.acceptedFormats, ["pdf"])
            XCTAssertEqual(configuration.maximumFileSize, 50_000_000)
            XCTAssertThrowsError(try DocumentFile.copy(from: sourceFileURL, acceptedFormats: configuration.acceptedFormats, maximumFileSize: configuration.maximumFileSize)) {
                XCTAssertEqual($0 as? DocumentCollectionError, .unsupportedFormat)
            }
        }
    }

    func testConfirmedLimitsApplyToEachFile() throws {
        for maximumFileSize in [50_000_000, 5_000_000] {
            var sourceFileURL = directory.appendingPathComponent("document.pdf")
            FileManager.default.createFile(atPath: sourceFileURL.path, contents: nil)
            let handle = try FileHandle(forWritingTo: sourceFileURL)
            defer {
                try? handle.close()
            }
            // Sparse files exercise the real limits without allocating an equally large Data value.
            try handle.truncate(atOffset: UInt64(maximumFileSize))
            let firstFile = try DocumentFile.copy(from: sourceFileURL, acceptedFormats: ["pdf"], maximumFileSize: maximumFileSize)
            let secondFile = try DocumentFile.copy(from: sourceFileURL, acceptedFormats: ["pdf"], maximumFileSize: maximumFileSize)
            XCTAssertNotEqual(firstFile.url, secondFile.url)
            XCTAssertEqual(try firstFile.url.resourceValues(forKeys: [.fileSizeKey]).fileSize, maximumFileSize)
            XCTAssertEqual(try secondFile.url.resourceValues(forKeys: [.fileSizeKey]).fileSize, maximumFileSize)

            try handle.truncate(atOffset: UInt64(maximumFileSize + 1))

            // Refresh the URL's cached metadata after resizing.
            sourceFileURL.removeAllCachedResourceValues()

            XCTAssertThrowsError(try DocumentFile.copy(from: sourceFileURL, acceptedFormats: ["pdf"], maximumFileSize: maximumFileSize)) {
                XCTAssertEqual($0 as? DocumentCollectionError, .fileTooLarge)
            }
        }
    }

    func testUnsupportedRequirementsDoNotBecomeSingleDocumentCollections() {
        for (formats, minimumTypes, maximumTypes, maximumFileSize): ([String], Int, Int, Int) in [
            (["pdf"], 2, 2, 50_000_000),  // 2 documents required. Proof-of-address should require 1.
            (["pdf"], 1, 0, 50_000_000),  // 0 maximum document types supported.
            (["pdf"], -1, 1, 50_000_000), // Negative minimum document types supported.
            (["pdf"], 1, 1, 0),           // Maximum file size is 0.
            ([], 1, 1, 50_000_000),       // No file types supported.
        ] {
            let requirement = AdditionalKYCDocumentRequirement(
                acceptedSubtypes: [.init(id: "id", label: "Label", description: nil)],
                acceptedFormats: formats,
                maxFileSizeBytes: maximumFileSize,
                minDocumentTypes: minimumTypes,
                maxDocumentTypes: maximumTypes,
                maxFilesPerDocumentType: nil,
                fileRequirements: "A localized hint supplied by the backend",
                instructions: []
            )

            XCTAssertThrowsError(try DocumentCollectionConfiguration(proofOfAddress: requirement)) {
                XCTAssertEqual($0 as? DocumentCollectionError, .unsupportedRequirement)
            }
        }
    }

    func testNonpositiveFileCountLimitIsUnsupported() {
        let requirement = AdditionalKYCDocumentRequirement(
            acceptedSubtypes: [.init(id: "salary", label: "Salary", description: nil)],
            acceptedFormats: ["pdf"],
            maxFileSizeBytes: 5_000_000,
            minDocumentTypes: 1,
            maxDocumentTypes: 1,
            maxFilesPerDocumentType: 0,
            fileRequirements: "PDF, up to 5 MB per file.",
            instructions: []
        )

        XCTAssertThrowsError(try DocumentCollectionConfiguration(document: requirement)) {
            XCTAssertEqual($0 as? DocumentCollectionError, .unsupportedRequirement)
        }
    }
}
