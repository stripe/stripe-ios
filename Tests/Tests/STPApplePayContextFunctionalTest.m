//
//  STPApplePayContextFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 2/24/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPApplePayContext.h"
#import "Stripe.h"

@interface STPApplePayContext (Private) <PKPaymentAuthorizationViewControllerDelegate>
@end

#pragma mark - STPApplePayTestDelegate

@interface STPApplePayTestDelegate : NSObject <STPApplePayContextDelegate>
@property (nonatomic) void (^piCompletion)(STPPaymentIntentClientSecretCompletionBlock);
@property (nonatomic) STPPaymentStatusBlock completion;
@end

@implementation STPApplePayTestDelegate

- (void)applePayContext:(__unused STPApplePayContext *)context didCompleteWithStatus:(STPPaymentStatus)status error:(NSError *)error {
    self.completion(status, error);
}
- (void)applePayContext:(__unused STPApplePayContext *)context didCreatePaymentMethod:(__unused NSString *)paymentMethodID completion:(__unused STPPaymentIntentClientSecretCompletionBlock)completion {
    self.piCompletion(completion);
}

@end

@interface STPApplePayContextFunctionalTest : XCTestCase

@end

@implementation STPApplePayContextFunctionalTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    STPApplePayTestDelegate *delegate = [STPApplePayTestDelegate new];
    delegate.completion = ^(STPPaymentStatus status, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqual(status, STPPaymentStatusSuccess);
    };
    delegate.piCompletion = ^(STPPaymentIntentClientSecretCompletionBlock completion) {
        NSString *pi;
        completion(pi, nil);
    };
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
