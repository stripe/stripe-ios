//
//  STPPaymentConfiguration+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

@interface STPPaymentConfiguration ()

@property (nonatomic, assign, readonly) BOOL applePayEnabled;
@property (nonatomic, assign, readonly) NSSet<NSString *> *_availableCountries;

@end

