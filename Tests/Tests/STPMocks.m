//
//  STPMocks.m
//  Stripe
//
//  Created by Ben Guo on 4/5/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPMocks.h"

#import "STPFixtures.h"
#import "STPPaymentContext+Private.h"
#import "UIViewController+Stripe_Promises.h"

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
    return [self staticCustomerContextWithCustomer:[STPFixtures customerWithSingleCardTokenSource]];
}

+ (STPCustomerContext *)staticCustomerContextWithCustomer:(STPCustomer *)customer {
    id mock = OCMClassMock([STPCustomerContext class]);
    OCMStub([mock retrieveCustomer:[OCMArg any]]).andDo(^(NSInvocation *invocation){
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(customer, nil);
    });
    OCMStub([mock selectDefaultCustomerSource:[OCMArg any] completion:[OCMArg invokeBlock]]);
    OCMStub([mock attachSourceToCustomer:[OCMArg any] completion:[OCMArg invokeBlock]]);
    return mock;
}

@end
