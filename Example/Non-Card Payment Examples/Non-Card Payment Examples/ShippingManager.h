//
//  ShippingManager.h
//  StripeExample
//
//  Created by Jack Flintermann on 10/22/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Contacts/Contacts.h>

@interface ShippingManager : NSObject

- (NSArray *)defaultShippingMethods;
- (void)fetchShippingCostsForAddress:(CNPostalAddress *)address completion:(void (^)(NSArray *shippingMethods, NSError *error))completion;

@end
