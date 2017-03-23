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
 YES if this type immediately gathers info and converts to a token/source
 at selection time
 ie show Add Card/Source VC when chosen
 
 If YES, this type shouldn't be allowed to be the selectedPaymentMethod
 (selecting it always generates a source that becomes the selection instead)
 */
- (BOOL)convertsToSourceAtSelection;


/**
 YES if sources of this type are allowed to be set as a default source
 */
- (BOOL)canBeDefaultSource;

- (STPSourceType)sourceType;

- (NSString *)analyticsString;

@end
