//
//  STPPaymentCoordinatorTest.m
//  Stripe
//
//  Created by Jack Flintermann on 4/7/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PassKit/PassKit.h>
#import "STPPaymentCoordinator.h"
#import "STPAPIClient.h"
#import "MockSTPPaymentCoordinatorDelegate.h"
#import "MockSTPAPIClient.h"

@interface TestSTPPaymentCoordinator : STPPaymentCoordinator
@property(nonatomic, copy)STPVoidBlock deallocBlock;
@end

@implementation TestSTPPaymentCoordinator

- (instancetype)initWithDelegate:(id<STPPaymentCoordinatorDelegate>)delegate
                    deallocBlock:(STPVoidBlock)deallocBlock {
    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    paymentRequest.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"Test" amount:[NSDecimalNumber one]]];
    STPAPIClient *apiClient = [MockSTPAPIClient new];
    self = [super initWithPaymentRequest:paymentRequest
                              apiAdapter:nil
                               apiClient:apiClient
                                delegate:delegate];
    if (self) {
        _deallocBlock = deallocBlock;
    }
    return self;
}

- (void)dealloc {
    if (self.deallocBlock) {
        self.deallocBlock();
    }
}

@end

@interface STPPaymentCoordinatorTest : XCTestCase
@property(nonatomic)PKPaymentRequest *paymentRequest;
@property(nonatomic)id<STPPaymentCoordinatorDelegate> retainedDelegate;
@end

@interface STPPaymentCoordinator(Test)<PKPaymentAuthorizationViewControllerDelegate>
@end

@implementation STPPaymentCoordinatorTest

- (void)setUp {
    [super setUp];
    [Stripe setDefaultPublishableKey:@"test"];
    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    paymentRequest.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"Test" amount:[NSDecimalNumber one]]];
    self.paymentRequest = paymentRequest;
}

- (void)testDoesNotDeallocateBeforeCompletion {
    MockSTPPaymentCoordinatorDelegate *delegate = [MockSTPPaymentCoordinatorDelegate new];
    self.retainedDelegate = delegate;
    __unused TestSTPPaymentCoordinator *coordinator = [[TestSTPPaymentCoordinator alloc] initWithDelegate:delegate deallocBlock:^{
        XCTFail(@"coordinator should not have been deallocated");
    }];
}


- (void)pending_testDeallocatesAfterCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"dealloc"];
    MockSTPPaymentCoordinatorDelegate *delegate = [MockSTPPaymentCoordinatorDelegate new];
    delegate.ignoresUnexpectedCallbacks = YES;
    self.retainedDelegate = delegate;
    
    @autoreleasepool {
        __unused TestSTPPaymentCoordinator *coordinator = [[TestSTPPaymentCoordinator alloc] initWithDelegate:delegate deallocBlock:^{
            [expectation fulfill];
        }];
        // TODO
    }
    
    [self waitForExpectationsWithTimeout:0.01 handler:nil];
}

- (void)testCallbacks_ApplePay_Cancel {
    XCTestExpectation *expectation = [self expectationWithDescription:@"cancelled"];
    MockSTPPaymentCoordinatorDelegate *delegate = [MockSTPPaymentCoordinatorDelegate new];
    delegate.onDidCancel = ^{
        [expectation fulfill];
    };
    STPPaymentCoordinator *coordinator = [[STPPaymentCoordinator alloc] initWithPaymentRequest:self.paymentRequest apiAdapter:nil apiClient:[STPAPIClient sharedClient] delegate:delegate];
    [coordinator paymentAuthorizationViewControllerDidFinish:[PKPaymentAuthorizationViewController new]];
    [self waitForExpectationsWithTimeout:0.01 handler:nil];
}

- (void)testCallbacks_ApplePay_Error {
    XCTestExpectation *expectation = [self expectationWithDescription:@"error"];
    MockSTPPaymentCoordinatorDelegate *delegate = [MockSTPPaymentCoordinatorDelegate new];
    NSError *expectedError = [NSError new];
    __weak typeof(self) weakSelf = self;
    delegate.onDidFailWithError = ^(NSError *error){
        _XCTPrimitiveAssertEqualObjects(weakSelf, error, @"", expectedError, @"");
        [expectation fulfill];
    };
    STPPaymentCoordinator *coordinator = [[STPPaymentCoordinator alloc] initWithPaymentRequest:self.paymentRequest apiAdapter:nil apiClient:[MockSTPAPIClient mockWithError:expectedError] delegate:delegate];
    [coordinator paymentAuthorizationViewController:[PKPaymentAuthorizationViewController new] didAuthorizePayment:[PKPayment new] completion:^(__unused PKPaymentAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [coordinator paymentAuthorizationViewControllerDidFinish:[PKPaymentAuthorizationViewController new]];
        });
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCallbacks_ApplePay_Success {
    XCTestExpectation *expectation = [self expectationWithDescription:@"error"];
    MockSTPPaymentCoordinatorDelegate *delegate = [MockSTPPaymentCoordinatorDelegate new];
    delegate.onDidCreatePaymentResult = ^(__unused STPPaymentResult *p, STPErrorBlock completion) {
        completion(nil);
    };
    delegate.onDidSucceed = ^{
        [expectation fulfill];
    };
    STPPaymentCoordinator *coordinator = [[STPPaymentCoordinator alloc] initWithPaymentRequest:self.paymentRequest apiAdapter:nil apiClient:[MockSTPAPIClient new] delegate:delegate];
    [coordinator paymentAuthorizationViewController:[PKPaymentAuthorizationViewController new] didAuthorizePayment:[PKPayment new] completion:^(__unused PKPaymentAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [coordinator paymentAuthorizationViewControllerDidFinish:[PKPaymentAuthorizationViewController new]];
        });
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
