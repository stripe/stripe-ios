//
//  VerificationSheetControllerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/5/21.
//

import Foundation
@testable import StripeIdentity

final class VerificationSheetControllerMock: VerificationSheetControllerProtocol {
    let flowController: VerificationSheetFlowControllerProtocol
    let dataStore: VerificationSessionDataStore

    private(set) var didLoadAndUpdateUI = false
    private(set) var didSaveData = false

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
        didSaveData = true
        completion(VerificationSheetAPIContent())
    }
}
