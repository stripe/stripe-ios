//
//  FBSnapshotTestCase+STPViewControllerLoading.m
//  StripeiOS Tests
//
//  Created by Brian Dorfman on 12/11/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "FBSnapshotTestCase+STPViewControllerLoading.h"
#import "STPCoreScrollViewController+Private.h"

@implementation FBSnapshotTestCase (STPViewControllerLoading)
- (UIView *)stp_preparedAndSizedViewForSnapshotTestFromViewController:(UIViewController *)viewController {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    UIWindow *testWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    testWindow.rootViewController = navController;
    testWindow.hidden = NO;

    // Test that loaded properly + loads them on first call
    XCTAssertNotNil(navController.view);
    XCTAssertNotNil(viewController.view);

    if ([viewController isKindOfClass:[STPCoreScrollViewController class]]) {
        UIScrollView *scrollView = ((STPCoreScrollViewController *)viewController).scrollView;
        [navController.view layoutIfNeeded];

        CGFloat topOffset = [scrollView convertPoint:scrollView.frame.origin toCoordinateSpace:navController.view].y;
        navController.view.frame = CGRectMake(0, 0, 320, topOffset + scrollView.contentSize.height + scrollView.contentInset.top + scrollView.contentInset.bottom);
    }

    return navController.view;
}
@end
