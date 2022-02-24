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
    var verificationSessionId: String
    var ephemeralKeySecret: String
    var apiClient: IdentityAPIClient
    let flowController: VerificationSheetFlowControllerProtocol
    let dataStore: VerificationPageDataStore
    let mlModelLoader: IdentityMLModelLoaderProtocol

    var delegate: VerificationSheetControllerDelegate?

    private(set) var didLoadAndUpdateUI = false
    private(set) var didRequestSaveData = false
    private(set) var didRequestSubmit = false
    private(set) var didFinishSaveDataExp = XCTestExpectation(description: "Saved data")
    private(set) var didFinishSubmitExp = XCTestExpectation(description: "Submitted")
    private(set) var numUploadedImages = 0

    init(
        verificationSessionId: String = "",
        ephemeralKeySecret: String = "",
        apiClient: IdentityAPIClient = IdentityAPIClientTestMock(),
        flowController: VerificationSheetFlowControllerProtocol = VerificationSheetFlowControllerMock(),
        dataStore: VerificationPageDataStore = .init(),
        mlModelLoader: IdentityMLModelLoaderProtocol = IdentityMLModelLoaderMock()
    ) {
        self.verificationSessionId = verificationSessionId
        self.ephemeralKeySecret = ephemeralKeySecret
        self.apiClient = apiClient
        self.flowController = flowController
        self.dataStore = dataStore
        self.mlModelLoader = mlModelLoader
    }

    func loadAndUpdateUI() {
        didLoadAndUpdateUI = true
    }

    func saveData(completion: @escaping (VerificationSheetAPIContent) -> Void) {
        didRequestSaveData = true
        didFinishSaveDataExp.fulfill()
        completion(VerificationSheetAPIContent())
    }

    func submit(completion: @escaping (VerificationSheetAPIContent) -> Void) {
        didRequestSubmit = true
        didFinishSubmitExp.fulfill()
        completion(VerificationSheetAPIContent())
    }

    func saveDocumentFileData(
        documentUploader: DocumentUploaderProtocol,
        completion: @escaping (VerificationSheetAPIContent) -> Void
    ) {
        // Wait to save data until after documents are uploaded
        documentUploader.frontBackUploadFuture.observe { [weak self] _ in
            self?.saveData(completion: completion)
        }
    }


    func uploadDocument(
        image: UIImage
    ) -> Future<String> {
        numUploadedImages += 1
        return Promise(value: "")
    }
}
