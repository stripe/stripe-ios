//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPUIVCStripeParentViewControllerTests.swift
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
}

class STPUIVCStripeParentViewControllerTests: XCTestCase {
    func testNilParent() {
        let vc = UIViewController()
        XCTAssertNil(vc.stp_parentViewControllerOfClass(UIViewController.self))
    }

    func testNavigationController() {
        let vc = UIViewController()
        let nav = UINavigationController(rootViewController: vc)
        let parent = vc.stp_parentViewControllerOfClass(UINavigationController.self) as? UINavigationController
        XCTAssertEqual(nav, parent)
    }

    func testDeepHeirarchy() {
        let topLevel = TestViewController()
        let vc = UIViewController()
        let nav = UINavigationController(rootViewController: vc)
        topLevel.addChild(nav)
        nav.didMove(toParent: topLevel)
        let parent = vc.stp_parentViewControllerOfClass(TestViewController.self) as? TestViewController
        XCTAssertEqual(topLevel, parent)
    }
}