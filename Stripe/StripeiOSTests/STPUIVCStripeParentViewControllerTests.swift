//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPUIVCStripeParentViewControllerTests.m
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import Stripe

class TestViewController: UIViewController {
}

class STPUIVCStripeParentViewControllerTests: XCTestCase {
    func testNilParent() {
        let vc = UIViewController()
        XCTAssertNil(vc.stp_parentViewControllerOf(UIViewController.self))
    }

    func testNavigationController() {
        let vc = UIViewController()
        let nav = UINavigationController(rootViewController: vc)
        let parent = vc.stp_parentViewControllerOf(UINavigationController.self) as? UINavigationController
        XCTAssertEqual(nav, parent)
    }

    func testDeepHeirarchy() {
        let topLevel = TestViewController()
        let vc = UIViewController()
        let nav = UINavigationController(rootViewController: vc)
        topLevel.addChild(nav)
        nav.didMove(toParent: topLevel)
        let parent = vc.stp_parentViewControllerOf(TestViewController.self) as? TestViewController
        XCTAssertEqual(topLevel, parent)
    }
}

/**
 #import <XCTest/XCTest.h>
 #import <UIKit/UIKit.h>


 @interface TestViewController : UIViewController
 @end

 @implementation TestViewController
 @end

 @interface STPUIVCStripeParentViewControllerTests : XCTestCase
 @end

 @implementation STPUIVCStripeParentViewControllerTests

 - (void)testNilParent {
     UIViewController *vc = [UIViewController new];
     XCTAssertNil([vc stp_parentViewControllerOfClass:[UIViewController class]]);
 }

 - (void)testNavigationController {
     UIViewController *vc = [UIViewController new];
     UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
     UINavigationController *parent = (UINavigationController *)[vc stp_parentViewControllerOfClass:[UINavigationController class]];
     XCTAssertEqual(nav, parent);
 }

 - (void)testDeepHeirarchy {
     UIViewController *topLevel = [TestViewController new];
     UIViewController *vc = [UIViewController new];
     UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
     [topLevel addChildViewController:nav];
     [nav didMoveToParentViewController:topLevel];
     TestViewController *parent = (TestViewController *)[vc stp_parentViewControllerOfClass:[TestViewController class]];
     XCTAssertEqual(topLevel, parent);
 }

 @end

 */
