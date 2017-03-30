//
//  STPFixtures.h
//  Stripe
//
//  Created by Ben Guo on 3/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>

@interface STPFixtures : NSObject

/**
 An Address object with all fields filled.
 */
+ (STPAddress *)address;

/**
 A CardParams object with all fields filled.
 */
+ (STPCardParams *)cardParams;

/**
 A Source object with type card
 */
+ (STPSource *)cardSource;

/**
 A Token for a card
 */
+ (STPToken *)cardToken;

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
 A PaymentConfiguration object with a fake publishable key. Use this to avoid
 triggering our asserts when publishable key is nil or invalid. All other values
 are at their original defaults.
 */
+ (STPPaymentConfiguration *)paymentConfiguration;

/**
 A Source object with type SEPA debit
 */
+ (STPSource *)sepaDebitSource;

/**
 An Address object for creating a SEPA source.
 */
+ (STPAddress *)sepaAddress;

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
