//
//  FBSnapshotTestCase+STPViewControllerLoading.h
//  StripeiOS Tests
//
//  Created by Brian Dorfman on 12/11/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

@interface FBSnapshotTestCase (STPViewControllerLoading)

/**
 Embeds the given controller in a navigation controller, prepares it for
 snapshot testing and returns the view controller's view.
 */
- (UIView *)stp_preparedAndSizedViewForSnapshotTestFromViewController:(UIViewController *)viewController;

/**
 Returns a navigation controller initialized with the given root view controller
 and prepares it for snapshot testing (adding it to a UIWindow and loading views)
 */
- (UINavigationController *)stp_navigationControllerForSnapshotTestWithRootVC:(UIViewController *)viewController;

/**
 Returns a view for snapshot testing from the topViewController of the given
 navigation controller, making necessary layout adjustments for
 `STPCoreScrollViewController`.
 */
- (UIView *)stp_preparedAndSizedViewForSnapshotTestFromNavigationController:(UINavigationController *)navController;

@end
