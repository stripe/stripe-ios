//
//  VerificationSheetFlowControllerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/5/21.
//

import Foundation
import UIKit
import XCTest
@testable import StripeIdentity

/// Mock to help us test behavior that relies on  VerificationSheetFlowController
final class VerificationSheetFlowControllerMock: VerificationSheetFlowControllerProtocol {
    let navigationController = UINavigationController()

    private(set) var didTransitionToFirstScreenExp = XCTestExpectation(description: "transitionToFirstScreen")
    private(set) var didTransitionToNextScreenExp = XCTestExpectation(description: "transitionToNextScreen")

    func transitionToFirstScreen(apiContent: VerificationSheetAPIContent, sheetController: VerificationSheetControllerProtocol) {
        didTransitionToFirstScreenExp.fulfill()
    }

    func transitionToNextScreen(apiContent: VerificationSheetAPIContent, sheetController: VerificationSheetControllerProtocol) {
        didTransitionToNextScreenExp.fulfill()
    }
}
