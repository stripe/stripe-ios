//
//  STPMocks.h
//  Stripe
//
//  Created by Ben Guo on 4/5/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
@import Stripe;

@interface STPMocks : NSObject

/**
 A PaymentConfiguration object with a fake publishable key and a fake apple
 merchant identifier that ignores the true value of [StripeAPI deviceSupportsApplePay]
 and bases its `applePayEnabled` value solely on what is set
 in `additionalPaymentOptions`
 */
+ (STPPaymentConfiguration *)paymentConfigurationWithApplePaySupportingDevice;

@end
