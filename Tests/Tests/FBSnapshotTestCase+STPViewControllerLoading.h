//
//  FBSnapshotTestCase+STPViewControllerLoading.h
//  StripeiOS Tests
//
//  Created by Brian Dorfman on 12/11/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

@interface FBSnapshotTestCase (STPViewControllerLoading)
- (UIView *)stp_preparedAndSizedViewForSnapshotTestFromViewController:(UIViewController *)viewController;
@end
