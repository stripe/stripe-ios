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
    var isFinishedCollecting = false

    weak var delegate: VerificationSheetFlowControllerDelegate?

    let navigationController = UINavigationController()

    private(set) var didTransitionToNextScreenExp = XCTestExpectation(description: "transitionToNextScreen")
    private(set) var transitionedWithStaticContentResult: Result<VerificationPage, Error>?
    private(set) var transitionedWithUpdateDataResult: Result<VerificationPageData, Error>?

    private(set) var replacedWithViewController: UIViewController?

    private(set) var didPopToScreenWithField: VerificationPageFieldType?


    init(uncollectedFields: Set<VerificationPageFieldType> = []) {
        self.uncollectedFields = uncollectedFields
    }

    func transitionToNextScreen(
        staticContentResult: Result<VerificationPage, Error>,
        updateDataResult: Result<VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping () -> Void
    ) {
        transitionedWithStaticContentResult = staticContentResult
        transitionedWithUpdateDataResult = updateDataResult
        didTransitionToNextScreenExp.fulfill()
        completion()
    }

    func replaceCurrentScreen(with viewController: UIViewController) {
        replacedWithViewController = viewController
    }

    func canPopToScreen(withField field: VerificationPageFieldType) -> Bool {
        return !uncollectedFields.contains(field)
    }

    func popToScreen(
        withField field: VerificationPageFieldType,
        shouldResetViewController: Bool
    ) {
        didPopToScreenWithField = field
    }

    func isFinishedCollectingData(for verificationPage: VerificationPage) -> Bool {
        return isFinishedCollecting
    }
}
