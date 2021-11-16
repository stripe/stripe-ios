//
//  DocumentTypeSelectViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/5/21.
//

import XCTest
@testable import StripeIdentity

final class DocumentTypeSelectViewControllerTest: XCTestCase {

    var dataStore: VerificationSessionDataStore!
    var mockFlowController: VerificationSheetFlowControllerMock!
    var mockSheetController: VerificationSheetControllerMock!

    override func setUp() {
        super.setUp()

        dataStore = .init()
        mockFlowController = .init()
        mockSheetController = .init(
            flowController: mockFlowController,
            dataStore: dataStore
        )
    }

    func testNonEmptyDocumentTypes() {
        let vc = makeViewController(withDocTypes: [
            "invalid_document_type": "foo",
            "id_card": "Custom ID Card Label",
            "passport": "Custom Passport Label",
        ])
        // Verify only passport & id card made it and ordered properly
        XCTAssertEqual(vc.documentTypeWithLabels, [
            .init(documentType: .passport, label: "Custom Passport Label"),
            .init(documentType: .idCard, label: "Custom ID Card Label")
        ])
    }

    func testOnlyInvalidDocumentTypes() {
        let vc = makeViewController(withDocTypes: [
            "invalid_document_type": "foo",
        ])
        // Verify default types and labels are used
        XCTAssertEqual(vc.documentTypeWithLabels, [
            .init(documentType: .passport, label: "Passport"),
            .init(documentType: .drivingLicense, label: "Driver's license"),
            .init(documentType: .idCard, label: "Identity card")
        ])
    }

    func testEmptyDocumentTypes() {
        let vc = makeViewController(withDocTypes: [:])
        // Verify default types and labels are used
        XCTAssertEqual(vc.documentTypeWithLabels, [
            .init(documentType: .passport, label: "Passport"),
            .init(documentType: .drivingLicense, label: "Driver's license"),
            .init(documentType: .idCard, label: "Identity card")
        ])
    }

    func testSelectionPersistence() throws {
        let vc = makeViewController(withDocTypes: [:])
        // Simulate user tapping the passport button
        vc.didTapButton(documentType: .passport)
        // Verify that dataStore is updated
        XCTAssertEqual(dataStore.idDocumentType, .passport)
        // Verify that saveData was called
        // Verify user was transitioned to next screen
        wait(for: [mockSheetController.didFinishSaveDataExp, mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }
}

// MARK: - Helpers

private extension DocumentTypeSelectViewControllerTest {
    func makeViewController(withDocTypes docTypeAllowlist: [String: String]) -> DocumentTypeSelectViewController {
        return DocumentTypeSelectViewController(
            sheetController: mockSheetController,
            staticContent: .init(
                buttonText: "",
                idDocumentTypeAllowlist: docTypeAllowlist,
                title: "",
                _allResponseFieldsStorage: nil
            )
        )
    }
}
