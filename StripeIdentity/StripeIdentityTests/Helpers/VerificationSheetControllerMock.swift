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

    private(set) var didLoadAndUpdateUI = false
    private(set) var didRequestSaveData = false
    private(set) var didFinishSaveDataExp = XCTestExpectation(description: "Saved data")
    private(set) var numUploadedImages = 0

    init(
        flowController: VerificationSheetFlowControllerMock,
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

    func uploadDocument(
        image: UIImage
    ) -> Future<String> {
        numUploadedImages += 1
        return Promise(value: "")
    }
}
