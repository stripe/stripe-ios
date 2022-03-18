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
    var uncollectedFields: Set<VerificationPageFieldType>

    weak var delegate: VerificationSheetFlowControllerDelegate?

    let navigationController = UINavigationController()

    private(set) var didTransitionToNextScreenExp = XCTestExpectation(description: "transitionToNextScreen")

    private(set) var replacedWithViewController: UIViewController?


    init(uncollectedFields: Set<VerificationPageFieldType> = []) {
        self.uncollectedFields = uncollectedFields
    }

    func transitionToNextScreen(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping () -> Void
    ) {
        didTransitionToNextScreenExp.fulfill()
        completion()
    }

    func replaceCurrentScreen(with viewController: UIViewController) {
        replacedWithViewController = viewController
    }

}
