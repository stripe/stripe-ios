//
//  STPMocks.m
//  Stripe
//
//  Created by Ben Guo on 4/5/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPMocks.h"

#import "STPFixtures.h"
#import "StripeiOS_Tests-Swift.h"

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

+ (STPCustomerContext *)staticCustomerContext {
    return [self staticCustomerContextWithCustomer:[STPFixtures customerWithSingleCardTokenSource]
                                    paymentMethods:@[[STPFixtures paymentMethod]]];
}

+ (STPCustomerContext *)staticCustomerContextWithCustomer:(STPCustomer *)customer paymentMethods:(NSArray<STPPaymentMethod *> *)paymentMethods {
    if (@available(iOS 13.0, *)) {
        return [[Testing_StaticCustomerContext_Objc alloc] initWithCustomer:customer paymentMethods:paymentMethods];
    } else {
        return nil;
    }
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
    return self.applePayEnabled;
}

@end

