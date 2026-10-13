//
//  SourceOfFundsModelTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 9/30/26.
//

@testable import StripeCryptoOnramp
import XCTest

@MainActor
final class SourceOfFundsModelTests: XCTestCase {
    func testTypeLimitsCountSourcesRatherThanFiles() {
        let model = SourceOfFundsModel(configuration: configuration)
        let salary = configuration.acceptedSubtypes[0]
        let savings = configuration.acceptedSubtypes[1]
        let investment = configuration.acceptedSubtypes[2]

        model.save(subtype: salary, files: [file("file_salary_1"), file("file_salary_2")])
        XCTAssertFalse(model.canSubmit)
        XCTAssertTrue(model.canAddSource)

        model.save(subtype: salary, files: [file("file_duplicate")])
        XCTAssertEqual(model.sources.count, 1)

        model.save(subtype: savings, files: [file("file_savings")])
        XCTAssertTrue(model.canSubmit)
        XCTAssertFalse(model.canAddSource)

        model.save(subtype: investment, files: [file("file_over_limit")])
        XCTAssertEqual(model.documents, [
            .init(documentSubtype: salary.id, fileIds: ["file_salary_1", "file_salary_2"]),
            .init(documentSubtype: savings.id, fileIds: ["file_savings"]),
        ])
    }

    func testEditingReplacesTheCategoryAndFilesAndRemovalReleasesTheCategory() {
        let model = SourceOfFundsModel(configuration: configuration)
        let salary = configuration.acceptedSubtypes[0]
        let savings = configuration.acceptedSubtypes[1]
        let investment = configuration.acceptedSubtypes[2]
        model.save(subtype: salary, files: [file("file_salary")])
        model.save(subtype: savings, files: [file("file_savings")])

        XCTAssertEqual(model.availableSubtypes(editing: salary.id), [salary, investment])
        model.save(subtype: investment, files: [file("file_investment")], replacing: salary.id)
        XCTAssertEqual(model.documents, [
            .init(documentSubtype: investment.id, fileIds: ["file_investment"]),
            .init(documentSubtype: savings.id, fileIds: ["file_savings"]),
        ])

        model.save(subtype: investment, files: [], replacing: investment.id)
        XCTAssertFalse(model.canSubmit)
        XCTAssertTrue(model.canAddSource)
        XCTAssertEqual(model.availableSubtypes(), [salary, investment])
        XCTAssertEqual(model.documents, [.init(documentSubtype: savings.id, fileIds: ["file_savings"])])
    }

    func testFileLimitAppliesPerSource() {
        var configuration = configuration
        configuration.maximumFilesPerDocumentType = 2
        let model = SourceOfFundsModel(configuration: configuration)
        let salary = configuration.acceptedSubtypes[0]
        let savings = configuration.acceptedSubtypes[1]

        model.save(subtype: salary, files: [file("salary_1"), file("salary_2")])
        model.save(subtype: savings, files: [file("savings_1"), file("savings_2")])
        XCTAssertTrue(model.canSubmit)
        XCTAssertEqual(model.documents.count, 2)

        model.save(subtype: salary, files: [file("salary_1"), file("salary_2"), file("salary_3")], replacing: salary.id)
        XCTAssertEqual(model.sources[0].files.count, 2)
    }

    private var configuration: DocumentCollectionConfiguration {
        .init(
            acceptedSubtypes: [
                .init(id: "salary", label: "Salary", description: nil),
                .init(id: "savings", label: "Savings", description: nil),
                .init(id: "investment", label: "Investment earnings", description: nil),
            ],
            acceptedFormats: ["pdf"],
            instructions: [],
            maximumFileSize: 5_000_000,
            uploadHint: "PDF, up to 5 MB per file.",
            minimumDocumentTypes: 2,
            maximumDocumentTypes: 2
        )
    }

    private func file(_ id: String) -> DocumentUploadModel.UploadedFile {
        .init(name: "\(id).pdf", fileID: id)
    }
}
