//
//  STPUIVCStripeParentViewControllerTests.m
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "UIViewController+Stripe_ParentViewController.h"

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
