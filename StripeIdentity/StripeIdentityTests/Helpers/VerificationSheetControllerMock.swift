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
@_spi(STP) import StripeCoreTestUtils
@testable import StripeIdentity

final class VerificationSheetControllerMock: VerificationSheetControllerProtocol {
    var apiClient: IdentityAPIClient
    let flowController: VerificationSheetFlowControllerProtocol
    var collectedData: StripeAPI.VerificationPageCollectedData
    let mlModelLoader: IdentityMLModelLoaderProtocol
    let analyticsClient: IdentityAnalyticsClient

    var delegate: VerificationSheetControllerDelegate?

    private(set) var didLoadAndUpdateUI = false

    private(set) var savedData: StripeAPI.VerificationPageCollectedData?
    private(set) var uploadedDocumentsResult: Result<DocumentUploaderProtocol.CombinedFileData, Error>?
    private(set) var uploadedSelfieResult: Result<VerificationPageDataSelfieFileData, Error>?

    init(
        apiClient: IdentityAPIClient = IdentityAPIClientTestMock(),
        flowController: VerificationSheetFlowControllerProtocol = VerificationSheetFlowControllerMock(),
        collectedData: StripeAPI.VerificationPageCollectedData = .init(),
        mlModelLoader: IdentityMLModelLoaderProtocol = IdentityMLModelLoaderMock(),
        analyticsClient: IdentityAnalyticsClient = .init(verificationSessionId: "", analyticsClient: MockAnalyticsClientV2())
    ) {
        self.apiClient = apiClient
        self.flowController = flowController
        self.collectedData = collectedData
        self.mlModelLoader = mlModelLoader
        self.analyticsClient = analyticsClient
    }

    func loadAndUpdateUI() {
        didLoadAndUpdateUI = true
    }

    func saveAndTransition(
        collectedData: StripeAPI.VerificationPageCollectedData,
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

    func saveSelfieFileDataAndTransition(
        selfieUploader: SelfieUploaderProtocol,
        trainingConsent: Bool?,
        completion: @escaping () -> Void
    ) {
        selfieUploader.uploadFuture?.observe { [weak self] result in
            self?.uploadedSelfieResult = result
            completion()
        }
    }

}
