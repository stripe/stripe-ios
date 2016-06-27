//
//  ManualInstallationTestTests.m
//  ManualInstallationTestTests
//
//  Created by Jack Flintermann on 5/15/15.
//  Copyright (c) 2015 stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestImageLoader.h"

@interface ManualInstallationTestTests : XCTestCase

@end

@implementation ManualInstallationTestTests

- (void)testBundleImagesAccessible {
    TestImageLoader *imageLoader = [[TestImageLoader alloc] init];
    XCTAssertNotNil(imageLoader.image);
}

@end
