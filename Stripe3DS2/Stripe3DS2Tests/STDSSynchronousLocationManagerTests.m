//
//  STDSSynchronousLocationManagerTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 1/24/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSSynchronousLocationManager.h"

@interface STDSSynchronousLocationManagerTests : XCTestCase

@end

@implementation STDSSynchronousLocationManagerTests

- (void)testLocationFetchIsSynchronous {
    id originalLocation = [[NSObject alloc] init];
    id location = originalLocation;
    
    location = [[STDSSynchronousLocationManager sharedManager] deviceLocation];
    // tests that location gets synchronously updated (even if it's to nil due to permissions while running tests)
    XCTAssertNotEqual(originalLocation, location);
}

@end
