//
//  MockCustomerContext.h
//  LocalizationTester
//
//  Created by Cameron Sabol on 12/14/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

@import Stripe;

@interface MockCustomerContext : NSObject <STPBackendAPIAdapter>

@property (nonatomic) BOOL neverRetrieveCustomer;

@end
