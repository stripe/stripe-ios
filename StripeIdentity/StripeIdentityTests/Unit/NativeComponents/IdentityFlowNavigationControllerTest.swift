//
//  IdentityFlowNavigationControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/17/21.
//

import XCTest
@testable import StripeIdentity

final class IdentityFlowNavigationControllerTest: XCTestCase {
    var navigationController: IdentityFlowNavigationController!

    override func setUp() {
        super.setUp()

        navigationController = IdentityFlowNavigationController(
            rootViewController: UIViewController(nibName: nil, bundle: nil)
        )
    }

    func testDisappearCallsDelegate() {
        let mockDelegate = MockDelegate()
        navigationController.identityDelegate = mockDelegate
        navigationController.viewDidDisappear(false)
        XCTAssertTrue(mockDelegate.didCallDismiss)
    }
}

private final class MockDelegate: IdentityFlowNavigationControllerDelegate {
    private(set) var didCallDismiss = false

    func identityFlowNavigationControllerDidDismiss(_ navigationController: IdentityFlowNavigationController) {
        didCallDismiss = true
    }
}
