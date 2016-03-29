//
//  STPPaymentAuthorizationViewControllerTests.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import "MockSTPAPIClient.h"
#import "MockSTPPAVCDelegate.h"

@interface STPPaymentAuthorizationViewControllerTests: XCTestCase
@property (nonatomic) NSString *merchantID;
@property (nonatomic) NSString *publishableKey;
@property (nonatomic) STPPaymentRequest *paymentRequest;
@property (nonatomic) MockSTPAPIClient *apiClient;
@property (nonatomic) STPPaymentAuthorizationViewController *sut;
@end

@implementation STPPaymentAuthorizationViewControllerTests

- (void)setUp {
    [super setUp];
    self.merchantID = @"apple_merchant_id";
    self.publishableKey = @"publishable_key";
    self.paymentRequest = [[STPPaymentRequest alloc] initWithAppleMerchantId:self.merchantID];
    self.apiClient = [[MockSTPAPIClient alloc] initWithPublishableKey:self.publishableKey];
    self.sut = [[STPPaymentAuthorizationViewController alloc] initWithPaymentRequest:self.paymentRequest
                                                                           apiClient:self.apiClient];
    UIViewController *vc = [UIViewController new];
    [UIApplication sharedApplication].keyWindow.rootViewController = vc;
    XCTAssertNotNil(vc.view);
    [vc presentViewController:self.sut animated:false completion:nil];
    XCTAssertNotNil(self.sut.view);
}

- (void)tearDown {
    [super tearDown];
    self.paymentRequest = nil;
    self.apiClient = nil;
    self.sut = nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)testFirstVCIsEmailVC {
    UIViewController *vc = self.sut.navigationController.topViewController;
    XCTAssertTrue([vc isKindOfClass:[STPEmailEntryViewController class]]);
}

- (void)testCancelingEmailEntryTellsDelegate {
    UIViewController *vc = self.sut.navigationController.topViewController;
    XCTestExpectation *exp = [self expectationWithDescription:@"cancel"];
    MockSTPPAVCDelegate *delegate = [MockSTPPAVCDelegate new];
    self.sut.delegate = delegate;
    delegate.onDidCancel = ^(){ [exp fulfill]; };
    XCTAssertNotNil(vc.view);

    UIBarButtonItem *cancelButton = vc.navigationItem.leftBarButtonItem;
    [cancelButton.target performSelector:cancelButton.action withObject:cancelButton];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma clang diagnostic pop

@end
