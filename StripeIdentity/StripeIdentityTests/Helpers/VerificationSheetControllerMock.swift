//
//  VerificationSheetControllerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/5/21.
//

import Foundation
import XCTest
import UIKit
@_spi(STP) import StripeCore
@testable import StripeIdentity

final class VerificationSheetControllerMock: VerificationSheetControllerProtocol {
    var apiClient: IdentityAPIClient
    let flowController: VerificationSheetFlowControllerProtocol
    var collectedData: VerificationPageCollectedData
    let mlModelLoader: IdentityMLModelLoaderProtocol

    var delegate: VerificationSheetControllerDelegate?

    private(set) var didLoadAndUpdateUI = false

    private(set) var savedData: VerificationPageCollectedData?
    private(set) var uploadedDocumentsResult: Result<DocumentUploaderProtocol.CombinedFileData, Error>?

    init(
        apiClient: IdentityAPIClient = IdentityAPIClientTestMock(),
        flowController: VerificationSheetFlowControllerProtocol = VerificationSheetFlowControllerMock(),
        collectedData: VerificationPageCollectedData = .init(),
        mlModelLoader: IdentityMLModelLoaderProtocol = IdentityMLModelLoaderMock()
    ) {
        self.apiClient = apiClient
        self.flowController = flowController
        self.collectedData = collectedData
        self.mlModelLoader = mlModelLoader
    }

    func loadAndUpdateUI() {
        didLoadAndUpdateUI = true
    }

    func saveAndTransition(
        collectedData: VerificationPageCollectedData,
        completion: @escaping () -> Void
    ) {
        savedData = collectedData
        completion()
    }

    func saveDocumentFileDataAndTransition(
        documentUploader: DocumentUploaderProtocol,
        completion: @escaping () -> Void
    ) {
        // Wait to save data until after documents are uploaded
        documentUploader.frontBackUploadFuture.observe { [weak self] result in
            self?.uploadedDocumentsResult = result
            completion()
        }
    }
}
