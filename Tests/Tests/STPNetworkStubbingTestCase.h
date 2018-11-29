//
//  STPNetworkStubbingTestCase.h
//  StripeiOS Tests
//
//  Created by Jack Flintermann on 11/24/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Test cases that subclass `STPNetworkStubbingTestCase` will automatically capture all network traffic when run with `recordingMode = YES` and save it to disk. When run with `recordingMode = NO`, they will use the persisted request/response pairs, and raise an exception if an unexpected HTTP request is made.
 */
@interface STPNetworkStubbingTestCase : XCTestCase
/// Set this to YES to record all traffic during this test. The test will then fail, to remind you to set this back to NO before pushing.
@property (nonatomic) BOOL recordingMode;
@end

NS_ASSUME_NONNULL_END
