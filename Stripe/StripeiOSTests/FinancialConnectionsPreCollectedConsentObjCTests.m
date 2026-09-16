//
//  FinancialConnectionsPreCollectedConsentObjCTests.m
//  StripeiOSTests
//

@import StripeCore;
@import XCTest;

@interface FinancialConnectionsPreCollectedConsentObjCTests : XCTestCase
@end

@implementation FinancialConnectionsPreCollectedConsentObjCTests

- (void)testInitializerRequiresConsentAndCollectedAt {
    STPFinancialConnectionsPreCollectedConsent *evidence =
        [[STPFinancialConnectionsPreCollectedConsent alloc] initWithConsent:@"fccons_123"
                                                                collectedAt:1725000123];

    XCTAssertEqualObjects(evidence.consent, @"fccons_123");
    XCTAssertEqual(evidence.collectedAt, 1725000123);
}

@end
