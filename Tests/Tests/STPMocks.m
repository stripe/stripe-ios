//
//  STPMocks.m
//  Stripe
//
//  Created by Ben Guo on 4/5/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPMocks.h"

#import "STPFixtures.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentContext+Private.h"
#import "UIViewController+Stripe_Promises.h"

@interface STPPaymentConfiguration (STPMocks)

/**
 Mock apple pay enabled response to just be based on setting and not hardware
 capability.

 `paymentConfigurationWithApplePaySupportingDevice` forwards calls to the
 real method to this stub
 */
- (BOOL)stpmock_applePayEnabled;

@end

@implementation STPMocks

+ (id)hostViewController {
    id mockVC = OCMClassMock([UIViewController class]);
    STPVoidPromise *didAppearPromise = [STPVoidPromise new];
    STPVoidPromise *willAppearPromise = [STPVoidPromise new];
    [didAppearPromise succeed];
    [willAppearPromise succeed];
    OCMStub([mockVC stp_didAppearPromise]).andReturn(didAppearPromise);
    OCMStub([mockVC stp_willAppearPromise]).andReturn(willAppearPromise);
    return mockVC;
}

+ (STPCustomerContext *)staticCustomerContext {
    return [self staticCustomerContextWithCustomer:[STPFixtures customerWithSingleCardTokenSource]
                                    paymentMethods:@[[STPFixtures paymentMethod]]];
}

+ (STPCustomerContext *)staticCustomerContextWithCustomer:(STPCustomer *)customer paymentMethods:(NSArray<STPPaymentMethod *> *)paymentMethods {
    id mock = OCMClassMock([STPCustomerContext class]);
    OCMStub([mock retrieveCustomer:[OCMArg any]]).andDo(^(NSInvocation *invocation){
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(customer, nil);
    });
    
    OCMStub([mock listPaymentMethodsForCustomerWithCompletion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        STPPaymentMethodsCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(paymentMethods, nil);
    });
    OCMStub([mock attachPaymentMethodToCustomer:[OCMArg any] completion:[OCMArg invokeBlock]]);
    return mock;
}

+ (STPPaymentConfiguration *)paymentConfigurationWithApplePaySupportingDevice {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.appleMerchantIdentifier = @"fake_apple_merchant_id";
    id partialMock = OCMPartialMock(config);
    OCMStub([partialMock applePayEnabled]).andCall(partialMock, @selector(stpmock_applePayEnabled));
    return partialMock;
}

@end

@implementation STPPaymentConfiguration (STPMocks)

- (BOOL)stpmock_applePayEnabled {
    return (self.additionalPaymentOptions & STPPaymentOptionTypeApplePay);
}

@end

