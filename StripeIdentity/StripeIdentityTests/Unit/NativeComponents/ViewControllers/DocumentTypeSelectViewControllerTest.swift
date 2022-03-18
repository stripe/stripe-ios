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

    func testNonEmptyDocumentTypes() {
        let vc = makeViewController(withDocTypes: [
            "invalid_document_type": "foo",
            "id_card": "Custom ID Card Label",
            "passport": "Custom Passport Label",
        ])
        // Verify only passport & id card made it and ordered properly
        XCTAssertEqual(vc.documentTypeWithLabels, [
            .init(documentType: .idCard, label: "Custom ID Card Label"),
            .init(documentType: .passport, label: "Custom Passport Label"),
        ])
    }

    func testOnlyInvalidDocumentTypes() {
        let vc = makeViewController(withDocTypes: [
            "invalid_document_type": "foo",
        ])
        // Verify default types and labels are used
        XCTAssertEqual(vc.documentTypeWithLabels, [
            .init(documentType: .drivingLicense, label: "Driver's license"),
            .init(documentType: .idCard, label: "Identity card"),
            .init(documentType: .passport, label: "Passport"),
        ])
    }

    func testEmptyDocumentTypes() {
        let vc = makeViewController(withDocTypes: [:])
        // Verify default types and labels are used
        XCTAssertEqual(vc.documentTypeWithLabels, [
            .init(documentType: .drivingLicense, label: "Driver's license"),
            .init(documentType: .idCard, label: "Identity card"),
            .init(documentType: .passport, label: "Passport"),
        ])
    }

    func testSingleDocumentType() {
        let instructionText = "Instruction text telling user to get their ID Card"
        let vc = makeViewController(withDocTypes: [
            "id_card": instructionText,
        ])
        // Verify view displays text instead of list
        XCTAssertNil(vc.viewModel.listViewModel)
        XCTAssertEqual(vc.viewModel.instructionText, instructionText)
        // Verify button
        guard let buttonViewModel = vc.buttonViewModel else {
            return XCTFail("Expected buttonViewModel to not be nil")
        }
        // Verify button tap
        buttonViewModel.didTap()
        XCTAssertEqual(mockSheetController.savedData?.idDocument?.type, .idCard)
    }

    func testMultipleDocumentType() {
        let vc = makeViewController(withDocTypes: [
            "id_card": "Custom ID Card Label",
            "passport": "Custom Passport Label",
        ])
        // Verify view displays list instead of text
        XCTAssertNil(vc.viewModel.instructionText)
        XCTAssertEqual(vc.viewModel.listViewModel?.items.count, 2)
        // Verify no button
        XCTAssertNil(vc.buttonViewModel)
        // Verify item tap
        vc.viewModel.listViewModel?.items.first?.onTap?()
        XCTAssertEqual(mockSheetController.savedData?.idDocument?.type, .idCard)
    }

    func testSelectionPersistence() throws {
        let vc = makeViewController(withDocTypes: [:])
        // Simulate user tapping the passport button
        vc.didTapOption(documentType: .passport)
        // Verify that saveData was called
        XCTAssertEqual(mockSheetController.savedData?.idDocument?.type, .passport)
    }
}

// MARK: - Helpers

private extension DocumentTypeSelectViewControllerTest {
    func makeViewController(withDocTypes docTypeAllowlist: [String: String]) -> DocumentTypeSelectViewController {
        return DocumentTypeSelectViewController(
            sheetController: mockSheetController,
            staticContent: .init(
                idDocumentTypeAllowlist: docTypeAllowlist,
                title: "",
                _allResponseFieldsStorage: nil
            )
        )
    }
}
