//
//  STPSTPViewWithSeparatorSnapshotTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "STPTestUtils.h"


@interface STPSTPViewWithSeparatorSnapshotTests : FBSnapshotTestCase

@end

@implementation STPSTPViewWithSeparatorSnapshotTests

//- (void)setUp {
//    [super setUp];
//
//    self.recordMode = YES;
//}

- (void)testDefaultAppearance {
    STPViewWithSeparator *view = [[STPViewWithSeparator alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 44.f)];
    view.backgroundColor = [UIColor whiteColor];
    STPSnapshotVerifyView(view, @"STPViewWithSeparator.defaultAppearance");
}

- (void)testHiddenTopSeparator {
    STPViewWithSeparator *view = [[STPViewWithSeparator alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 44.f)];
    view.backgroundColor = [UIColor whiteColor];
    view.topSeparatorHidden = YES;
    STPSnapshotVerifyView(view, @"STPViewWithSeparator.hiddenTopSeparator");
}

@end
