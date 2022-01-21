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
    weak var delegate: VerificationSheetFlowControllerDelegate?

    let navigationController = UINavigationController()

    private(set) var didTransitionToNextScreenExp = XCTestExpectation(description: "transitionToNextScreen")
    private(set) var didReplaceCurrentScreenExp = XCTestExpectation(description: "replaceCurrentScreen")

    func transitionToNextScreen(apiContent: VerificationSheetAPIContent, sheetController: VerificationSheetControllerProtocol) {
        didTransitionToNextScreenExp.fulfill()
    }

    func replaceCurrentScreen(with viewController: UIViewController) {
        didReplaceCurrentScreenExp.fulfill()
    }

}
