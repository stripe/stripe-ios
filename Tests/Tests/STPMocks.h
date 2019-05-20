//
//  STPMocks.h
//  Stripe
//
//  Created by Ben Guo on 4/5/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>

@interface STPMocks : NSObject

/**
 A view controller that can be used as a STPPaymentContext's hostViewController.
 */
+ (id)hostViewController;

/**
 A stateless customer context that always retrieves the same customer object.
 */
+ (STPCustomerContext *)staticCustomerContext;

/**
 A static customer context that always retrieves the given customer and the given payment methods.
 Selecting a default source and attaching a source have no effect.
 */
+ (STPCustomerContext *)staticCustomerContextWithCustomer:(STPCustomer *)customer paymentMethods:(NSArray<STPPaymentMethod *> *)paymentMethods;

/**
 A PaymentConfiguration object with a fake publishable key and a fake apple
 merchant identifier that ignores the true value of [Stripe deviceSupportsApplePay]
 and bases its `applePayEnabled` value solely on what is set
 in `additionalPaymentOptions`
 */
+ (STPPaymentConfiguration *)paymentConfigurationWithApplePaySupportingDevice;

@end
