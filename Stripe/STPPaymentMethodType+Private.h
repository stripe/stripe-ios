//
//  STPPaymentMethodType+Private.h
//  Stripe
//
//  Created by Brian Dorfman on 3/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodType.h"
#import "STPSource.h"

@interface STPPaymentMethodType ()


/**
 YES if this type needs to get information at selection time 
 
 ie show Add Card/Source VC when chosen
 */
- (BOOL)gathersInfoAtSelection;


/**
 YES if sources of this type are allowed to be set as a default source
 */
- (BOOL)canBeDefaultSource;

- (STPSourceType)sourceType;

- (NSString *)analyticsString;

@end
