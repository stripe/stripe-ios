//
//  DocumentTypeSelectViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/5/21.
//

import XCTest
@testable import StripeIdentity

final class DocumentTypeSelectViewControllerTest: XCTestCase {

    var mockSheetController: VerificationSheetControllerMock!

    override func setUp() {
        super.setUp()

        mockSheetController = .init()
    }

    func testNonEmptyDocumentTypes() throws {
        let vc = try makeViewController(withDocTypes: [
            "invalid_document_type": "foo",
            DocumentType.idCard.rawValue: "Custom ID Card Label",
            DocumentType.passport.rawValue: "Custom Passport Label",
        ])
        // Verify only passport & id card made it and ordered properly
        XCTAssertEqual(vc.documentTypeWithLabels, [
            .init(documentType: .idCard, label: "Custom ID Card Label"),
            .init(documentType: .passport, label: "Custom Passport Label"),
        ])
    }

    func testOnlyInvalidDocumentTypes() throws {
        do {
            let _ = try makeViewController(withDocTypes: [
                "invalid_document_type": "foo",
            ])
            XCTFail("Expected `DocumentTypeSelectViewControllerError`")
        } catch DocumentTypeSelectViewControllerError.noValidDocumentTypes(let providedDocumentTypes) {
            XCTAssertEqual(providedDocumentTypes, ["invalid_document_type"])
        } catch {
            throw error
        }
    }

    func testEmptyDocumentTypes() throws {
        do {
            let _ = try makeViewController(withDocTypes: [:])
            XCTFail("Expected `DocumentTypeSelectViewControllerError`")
        } catch DocumentTypeSelectViewControllerError.noValidDocumentTypes(let providedDocumentTypes) {
            XCTAssertEqual(providedDocumentTypes, [])
        } catch {
            throw error
        }
    }

    func testSingleDocumentType() throws {
        let instructionText = "Instruction text telling user to get their ID Card"
        let vc = try DocumentTypeSelectViewController(
            sheetController: mockSheetController,
            staticContent: .init(
                body: instructionText,
                idDocumentTypeAllowlist: [
                    DocumentType.idCard.rawValue: "ID Card",
                ],
                title: ""
            )
        )
        // Verify view displays text instead of list
        XCTAssertNil(vc.viewModel.listViewModel)
        XCTAssertEqual(vc.viewModel.instructionText, instructionText)
        // Verify button
        guard let buttonViewModel = vc.buttonViewModel else {
            return XCTFail("Expected buttonViewModel to not be nil")
        }
        // Verify button tap
        buttonViewModel.didTap()
        XCTAssertEqual(mockSheetController.savedData?.idDocumentType, .idCard)
    }

    func testMultipleDocumentType() throws {
        let vc = try makeViewController(withDocTypes: [
            DocumentType.idCard.rawValue: "Custom ID Card Label",
            DocumentType.passport.rawValue: "Custom Passport Label",
        ])
        // Verify view displays list instead of text
        XCTAssertNil(vc.viewModel.instructionText)
        XCTAssertEqual(vc.viewModel.listViewModel?.items.count, 2)
        // Verify no button
        XCTAssertNil(vc.buttonViewModel)
        // Verify item tap
        vc.viewModel.listViewModel?.items.first?.onTap?()
        XCTAssertEqual(mockSheetController.savedData?.idDocumentType, .idCard)
    }

    func testSelectionPersistence() throws {
        let vc = try makeViewController(withDocTypes: [
            DocumentType.drivingLicense.rawValue: "Driver's License",
            DocumentType.idCard.rawValue: "Identity Card",
            DocumentType.passport.rawValue: "Passport",
        ])
        // Simulate user tapping the passport button
        vc.didTapOption(documentType: .passport)
        // Verify that saveData was called
        XCTAssertEqual(mockSheetController.savedData?.idDocumentType, .passport)
    }
}

// MARK: - Helpers

private extension DocumentTypeSelectViewControllerTest {
    func makeViewController(withDocTypes docTypeAllowlist: [String: String]) throws -> DocumentTypeSelectViewController {
        return try DocumentTypeSelectViewController(
            sheetController: mockSheetController,
            staticContent: .init(
                body: nil,
                idDocumentTypeAllowlist: docTypeAllowlist,
                title: "",
                _allResponseFieldsStorage: nil
            )
        )
    }
}
