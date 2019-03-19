//
//  MockCustomerContext.h
//  LocalizationTester
//
//  Created by Cameron Sabol on 12/14/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

@interface MockCustomerContext : STPCustomerContext

@property (nonatomic) BOOL neverRetrieveCustomer;

@end
