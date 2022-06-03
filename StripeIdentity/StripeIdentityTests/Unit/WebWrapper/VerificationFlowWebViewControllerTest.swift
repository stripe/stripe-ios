//
//  VerificationFlowWebViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import StripeIdentity

@available(iOS 14.3, *)
final class VerificationFlowWebViewControllerTest: XCTestCase {
    let mockSecret = VerificationClientSecret(verificationSessionId: "", urlToken: "123")

    private var viewController: VerificationFlowWebViewController!
    private var result: IdentityVerificationSheet.VerificationFlowResult?

    override func setUp() {
        super.setUp()

        // Reset result
        result = nil

        // Make view controller
        let navigationController = VerificationFlowWebViewController.makeInNavigationController(clientSecret: mockSecret, delegate: self)
        guard let viewController = navigationController.viewControllers.first as? VerificationFlowWebViewController else {
            return XCTFail("Expected `VerificationFlowWebViewController `")
        }
        self.viewController = viewController

        // Mock lifecycle
        viewController.viewDidLoad()
        viewController.viewWillAppear(false)
        viewController.viewDidAppear(false)
    }

    func testCanceledResult() {
        // Mock that user closes view without finishing
        viewController.viewDidDisappear(false)
        guard case .flowCanceled = result else {
            return XCTFail("Expected `flowCanceled`")
        }
    }

    func testCompletedResult() {
        // Mock that user closes view after reaching success URL
        viewController.verificationWebView?.webView.load(URLRequest(url: VerifyWebURLHelper.successURL))
        viewController.viewDidDisappear(false)
        guard case .flowCompleted = result else {
            return XCTFail("Expected `flowCompleted`")
        }
    }
}

@available(iOS 14.3, *)
extension VerificationFlowWebViewControllerTest: VerificationFlowWebViewControllerDelegate {
    func verificationFlowWebViewController(_ viewController: VerificationFlowWebViewController, didFinish result: IdentityVerificationSheet.VerificationFlowResult) {
        self.result = result
    }
}
