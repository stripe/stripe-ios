//
//  ErrorViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 6/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
import UIKit
import XCTest

@testable import StripeIdentity

@MainActor
final class ErrorViewControllerTest: XCTestCase {

    var mockAnalyticsClient: MockAnalyticsClientV2!
    var mockSheetController: VerificationSheetControllerMock!

    override func setUp() {
        super.setUp()

        mockAnalyticsClient = .init()
        mockSheetController = .init(
            analyticsClient: IdentityAnalyticsClient(
                verificationSessionId: "",
                analyticsClient: mockAnalyticsClient
            )
        )
    }

    func testErrorLoggedOnInit() {
        let mockError = NSError(domain: "custom_domain", code: 100)
        _ = ErrorViewController(
            sheetController: mockSheetController,
            error: .error(mockError),
            filePath: "mock_file_path",
            line: 123
        )

        let errorAnalytics = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "generic_error"
        )
        XCTAssertEqual(errorAnalytics.count, 1)

        let metadata = errorAnalytics.first?["event_metadata"] as? [String: Any]
        let errorDict = metadata?["error_details"] as? [String: Any]
        XCTAssertNotNil(errorDict)
        XCTAssertEqual(errorDict?["domain"] as? String, "custom_domain")
        XCTAssertEqual(errorDict?["code"] as? Int, 100)
        XCTAssertEqual(errorDict?["file"] as? String, "mock_file_path")
        XCTAssertEqual(errorDict?["line"] as? UInt, 123)
    }

    func testTappingContinueButton() async {
        let continueText = "continue"
        let backText = "back"
        let forceConfirmStarted = expectation(description: "Force confirm started")
        forceConfirmStarted.assertForOverFulfill = false
        var forceConfirmCount = 0
        mockSheetController.forceDocumentFrontAndDecideBackHandler = {
            forceConfirmCount += 1
            forceConfirmStarted.fulfill()
            return false
        }
        let vc = ErrorViewController(
            sheetController: mockSheetController,
            error: .inputError(
                .init(
                    backButtonText: backText, body: "body", continueButtonText: continueText, requirement: .idDocumentFront, title: "title"
                )
            )
        )

        XCTAssertEqual(vc.buttonViewModels.count, 2)
        XCTAssertEqual(vc.buttonViewModels[0].text, continueText)
        XCTAssertEqual(vc.buttonViewModels[0].state, .enabled)

        XCTAssertEqual(vc.buttonViewModels[1].text, backText)
        XCTAssertEqual(vc.buttonViewModels[1].state, .enabled)

        // mock click button tap
        vc.buttonViewModels[0].didTap()
        XCTAssertEqual(vc.buttonViewModels[0].state, .loading)
        XCTAssertEqual(vc.buttonViewModels[1].state, .disabled)
        // A second tap while saving does not force-confirm again
        vc.buttonViewModels[0].didTap()
        await fulfillment(of: [forceConfirmStarted], timeout: 1)
        XCTAssertEqual(forceConfirmCount, 1)
    }

    func testFailedContinueAllowsRetry() async {
        // Given force-confirming the document front fails
        let forceConfirmExp = expectation(description: "Force confirm attempted")
        mockSheetController.forceDocumentFrontAndDecideBackHandler = {
            forceConfirmExp.fulfill()
            throw NSError(domain: "mock_error", code: 100)
        }
        let vc = ErrorViewController(
            sheetController: mockSheetController,
            error: .inputError(
                .init(
                    backButtonText: "back",
                    body: "body",
                    continueButtonText: "continue",
                    requirement: .idDocumentFront,
                    title: "title"
                )
            )
        )

        // When the user taps continue
        vc.buttonViewModels[0].didTap()

        // Then both buttons become enabled again so the user can retry
        await fulfillment(
            of: [
                forceConfirmExp,
                expectation(for: vc, keyPath: \.buttonViewModels[0].state, equalsToValue: .enabled),
            ],
            timeout: 4
        )
        XCTAssertEqual(vc.buttonViewModels[1].state, .enabled)
    }

    func testTryAgainReturnsToCaptureScreenAndSavesAgain() throws {
        // Given a capture screen with a failed upload, under a generic error
        let captureViewController = MockCaptureViewController()
        let navigationController = SpyNavigationController(
            rootViewController: UIViewController(nibName: nil, bundle: nil)
        )
        let errorViewController = pushError(above: captureViewController, in: navigationController)
        let tryAgainButton = try XCTUnwrap(errorViewController.buttonViewModels.first)
        XCTAssertEqual(tryAgainButton.text, String.Localized.tryAgain)

        // When the user taps Try again
        tryAgainButton.didTap()

        // Then the flow returns to the capture screen without resetting it, and saves the capture again
        XCTAssertTrue(navigationController.poppedToViewController === captureViewController)
        XCTAssertEqual(navigationController.popViewControllerCount, 0)
        XCTAssertEqual(captureViewController.retrySaveCount, 1)
    }

    func testGenericErrorWithoutFailedUploadDoesNotOfferTryAgain() {
        // Given a capture screen whose uploads did not fail, under a generic error
        let captureViewController = MockCaptureViewController()
        captureViewController.canRetryFailedUploads = false
        let navigationController = makeNavigationController()
        let errorViewController = pushError(above: captureViewController, in: navigationController)

        // Then it offers only Go Back
        XCTAssertEqual(errorViewController.buttonViewModels.map(\.text), ["Go Back"])
    }

    func testGenericErrorWithoutCaptureScreenDoesNotOfferTryAgain() {
        // Given a generic error above a screen that has no capture
        let navigationController = makeNavigationController()
        let errorViewController = pushError(
            above: UIViewController(nibName: nil, bundle: nil),
            in: navigationController
        )

        // Then it offers only Go Back
        XCTAssertEqual(errorViewController.buttonViewModels.map(\.text), ["Go Back"])
    }
}

private extension ErrorViewControllerTest {
    func makeNavigationController() -> UINavigationController {
        UINavigationController(rootViewController: UIViewController(nibName: nil, bundle: nil))
    }

    /// The test keeps `navigationController`, because the error screen holds it weakly.
    func pushError(
        above viewController: UIViewController,
        in navigationController: UINavigationController
    ) -> ErrorViewController {
        let errorViewController = ErrorViewController(
            sheetController: mockSheetController,
            error: .error(NSError(domain: "mock_error", code: 0))
        )
        navigationController.setViewControllers(
            navigationController.viewControllers + [viewController, errorViewController],
            animated: false
        )
        return errorViewController
    }
}

private final class MockCaptureViewController: UIViewController, RetriesSaveAfterError {
    var canRetryFailedUploads = true
    private(set) var retrySaveCount = 0

    func retrySaveAfterError() {
        retrySaveCount += 1
    }
}

/// Records pops, because without a window an animated pop does not finish, so the stack does not change.
private final class SpyNavigationController: UINavigationController {
    private(set) var poppedToViewController: UIViewController?
    private(set) var popViewControllerCount = 0

    override func popToViewController(
        _ viewController: UIViewController,
        animated: Bool
    ) -> [UIViewController]? {
        poppedToViewController = viewController
        return super.popToViewController(viewController, animated: animated)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        popViewControllerCount += 1
        return super.popViewController(animated: animated)
    }
}
