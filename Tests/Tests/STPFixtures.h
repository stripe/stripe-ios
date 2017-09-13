//
//  STPFixtures.h
//  Stripe
//
//  Created by Ben Guo on 3/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <PassKit/PassKit.h>
#import <Stripe/Stripe.h>

@interface STPFixtures : NSObject

/**
 An Address object with all fields filled.
 */
+ (STPAddress *)address;

/**
 A PKPaymentObject with test payment data.
 */
+ (PKPayment *)applePayPayment;

/**
 A BankAccountParams object with all fields filled.
 */
+ (STPBankAccountParams *)bankAccountParams;

/**
 A CardParams object with a valid number, expMonth, expYear, and cvc.
 */
+ (STPCardParams *)cardParams;

/**
 A valid card object
 */
+ (STPCard *)card;

/**
 A Source object with type card
 */
+ (STPSource *)cardSource;

/**
 A Customer object with a single card token in its sources array, and
 default_source set to that card token.
 */
+ (STPCustomer *)customerWithSingleCardTokenSource;

/**
 A Source object with type iDEAL
 */
+ (STPSource *)iDEALSource;

/**
 A Source object with type Alipay
 */
+ (STPSource *)alipaySource;

/**
 A Source object with type Alipay and a native redirect url
 */
+ (STPSource *)alipaySourceWithNativeUrl;

/**
 A PaymentConfiguration object with a fake publishable key. Use this to avoid
 triggering our asserts when publishable key is nil or invalid. All other values
 are at their original defaults.
 */
+ (STPPaymentConfiguration *)paymentConfiguration;

/**
 A customer-scoped ephemeral key that expires in 100 seconds.
 */
+ (STPEphemeralKey *)ephemeralKey;

/**
 A customer-scoped ephemeral key that expires in 10 seconds.
 */
+ (STPEphemeralKey *)expiringEphemeralKey;

@end
