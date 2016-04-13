//
//  STPPaymentAuthorizationViewControllerTests.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import "STPEmailEntryViewController.h"
#import "MockSTPAPIClient.h"
#import "MockSTPPAVCDelegate.h"

@interface STPPaymentAuthorizationViewControllerTests: XCTestCase
@property (nonatomic, strong) NSString *merchantID;
@property (nonatomic, strong) NSString *publishableKey;
@property (nonatomic, strong) PKPaymentRequest *paymentRequest;
@property (nonatomic, strong) MockSTPAPIClient *apiClient;
@property (nonatomic, strong) STPPaymentAuthorizationViewController *sut;
@property (nonatomic, strong) MockSTPPAVCDelegate *delegate;
@end

@implementation STPPaymentAuthorizationViewControllerTests

- (void)setUp {
    [super setUp];
    self.merchantID = @"apple_merchant_id";
    self.publishableKey = @"publishable_key";
    self.paymentRequest = [PKPaymentRequest new];
    self.paymentRequest.merchantIdentifier = self.merchantID;
    self.apiClient = [[MockSTPAPIClient alloc] initWithPublishableKey:self.publishableKey];
    self.sut = [[STPPaymentAuthorizationViewController alloc] initWithPaymentRequest:self.paymentRequest
                                                                           apiClient:self.apiClient];
    self.delegate = [MockSTPPAVCDelegate new];
    self.sut.delegate = self.delegate;
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
    self.delegate.onDidCancel = ^(){ [exp fulfill]; };
    XCTAssertNotNil(vc.view);

    UIBarButtonItem *cancelButton = vc.navigationItem.leftBarButtonItem;
    [cancelButton.target performSelector:cancelButton.action withObject:cancelButton];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

// TODO: I'm not sure what our strategy should be for testing this VC.
// We don't have callbacks for navigation controller transitions, which we would
// need for async testing. Perhaps we should add a delegate method
// that gets called when a transition to a new VC completes.

#pragma clang diagnostic pop

@end
