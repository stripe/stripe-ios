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
 A Customer object with a single card token in its sources array, and
 default_source set to that card token.
 */
+ (STPCustomer *)customerWithSingleCardTokenSource;

/**
 A PaymentConfiguration object with a fake publishable key. Use this to avoid
 triggering our asserts when publishable key is nil or invalid. All other values
 are at their original defaults.
 */
+ (STPPaymentConfiguration *)paymentConfiguration;

/**
 A stateless API adapter that always retrieves the same customer object.
 */
+ (id<STPBackendAPIAdapter>)staticAPIAdapter;

/**
 A stateless API adapter that always retrieves the given customer.
 selectDefaultSource and attachSource immediately call their completion blocks
 with nil.
 */
+ (id<STPBackendAPIAdapter>)staticAPIAdapterWithCustomer:(STPCustomer *)customer;

@end
