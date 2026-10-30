//
//  STPAPIClientObjectiveCTests.m
//  StripeCoreTests
//

@import StripeCore;
@import XCTest;

#import "StripeCoreTests-Swift.h"

@interface STPAPIClientObjectiveCTests : XCTestCase
@end

@implementation STPAPIClientObjectiveCTests

- (void)testInitializerRecordsObjectiveCUsage {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_example"];

    XCTAssertTrue([STPAnalyticsClientTest usesObjectiveCAPIForClient:client]);
    XCTAssertEqualObjects(client.publishableKey, @"pk_test_example");
}

- (void)testSharedClientRecordsObjectiveCUsage {
    STPAPIClient *client = [STPAPIClient sharedClient];

    XCTAssertTrue([STPAnalyticsClientTest usesObjectiveCAPIForClient:client]);
    XCTAssertEqual(client, [STPAPIClient sharedClient]);
}

- (void)testPublishableKeyPreservesObjectiveCBehavior {
    STPAPIClient *client = [[STPAPIClient alloc] init];
    XCTAssertFalse([STPAnalyticsClientTest usesObjectiveCAPIForClient:client]);

    client.publishableKey = @"pk_test_example";
    XCTAssertTrue([STPAnalyticsClientTest usesObjectiveCAPIForClient:client]);
    XCTAssertEqualObjects(client.publishableKey, @"pk_test_example");

    client.publishableKey = nil;
    XCTAssertTrue([STPAnalyticsClientTest usesObjectiveCAPIForClient:client]);
}

@end
