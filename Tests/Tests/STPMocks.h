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
