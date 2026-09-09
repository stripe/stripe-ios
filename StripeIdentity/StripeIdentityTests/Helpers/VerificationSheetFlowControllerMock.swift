//
//  VerificationSheetFlowControllerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/5/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import XCTest

@testable import StripeIdentity

/// Mock to help us test behavior that relies on  VerificationSheetFlowController
final class VerificationSheetFlowControllerMock: VerificationSheetFlowControllerProtocol {
    var documentUploader: StripeIdentity.DocumentUploaderProtocol?

    var uncollectedFields: Set<StripeAPI.VerificationPageFieldType>
    var isFinishedCollecting = false
    var analyticsLastScreen: IdentityFlowViewController?

    var visitedIndividualWelcomePage = false

    weak var delegate: VerificationSheetFlowControllerDelegate?

    let navigationController = UINavigationController()

    private(set) var didTransitionToNextScreenExp = XCTestExpectation(
        description: "transitionToNextScreen"
    )
    private(set) var transitionedWithStaticContentResult: Result<StripeAPI.VerificationPage, Error>?
    private(set) var transitionedWithUpdateDataResult: Result<StripeAPI.VerificationPageData, Error>?

    private(set) var replacedWithViewController: UIViewController?

    private(set) var didPopToScreenWithField: StripeAPI.VerificationPageFieldType?

    init(
        uncollectedFields: Set<StripeAPI.VerificationPageFieldType> = []
    ) {
        self.uncollectedFields = uncollectedFields
    }

    func transitionToNextScreen(
        skipTestMode: Bool,
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping () -> Void
    ) {
        // do something to skipTestMode
        transitionedWithStaticContentResult = staticContentResult
        transitionedWithUpdateDataResult = updateDataResult
        didTransitionToNextScreenExp.fulfill()
        completion()
    }

    func transitionToCountryNotListedScreen(
        staticContentResult: Result<StripeCore.StripeAPI.VerificationPage, Error>,
        sheetController: StripeIdentity.VerificationSheetControllerProtocol,
        missingType: StripeIdentity.IndividualFormElement.MissingType
    ) {
        // no-op
    }

    func transitionToIndividualScreen(
        staticContentResult: Result<StripeCore.StripeAPI.VerificationPage, Error>,
        sheetController: StripeIdentity.VerificationSheetControllerProtocol
    ) {
        // no-op
    }

    func transitionToSelfieCaptureScreen(
        staticContentResult: Result<StripeCore.StripeAPI.VerificationPage, Error>,
        sheetController: StripeIdentity.VerificationSheetControllerProtocol
    ) {
        // no-op
    }

    func transitionToDocumentCaptureScreen(
        staticContentResult: Result<StripeCore.StripeAPI.VerificationPage, Error>,
        sheetController: StripeIdentity.VerificationSheetControllerProtocol
    ) {
        // no-op
    }

    func transitionToErrorScreen(
        sheetController: StripeIdentity.VerificationSheetControllerProtocol,
        error: Error,
        completion: @escaping () -> Void
    ) {
        // no-op
    }

    func replaceCurrentScreen(with viewController: UIViewController) {
        replacedWithViewController = viewController
    }

    func canPopToScreen(withField field: StripeAPI.VerificationPageFieldType) -> Bool {
        return !uncollectedFields.contains(field)
    }

    func popToScreen(
        withField field: StripeAPI.VerificationPageFieldType,
        shouldResetViewController: Bool
    ) {
        didPopToScreenWithField = field
    }

    func isFinishedCollectingData(for verificationPage: StripeAPI.VerificationPage) -> Bool {
        return isFinishedCollecting
    }
}
