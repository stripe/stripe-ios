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
    let flowController: VerificationSheetFlowControllerProtocol
    let dataStore: VerificationSessionDataStore
    var mockCameraFeed: MockIdentityDocumentCameraFeed?

    private(set) var didLoadAndUpdateUI = false
    private(set) var didRequestSaveData = false
    private(set) var didRequestSubmit = false
    private(set) var didFinishSaveDataExp = XCTestExpectation(description: "Saved data")
    private(set) var didFinishSubmitExp = XCTestExpectation(description: "Submitted")
    private(set) var numUploadedImages = 0

    init(
        flowController: VerificationSheetFlowControllerProtocol,
        dataStore: VerificationSessionDataStore
    ) {
        self.flowController = flowController
        self.dataStore = dataStore
    }

    func loadAndUpdateUI(clientSecret: String) {
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

    func uploadDocument(
        image: UIImage
    ) -> Future<String> {
        numUploadedImages += 1
        return Promise(value: "")
    }
}
