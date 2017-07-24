//
//  NSError+StripeInternal.h
//  Stripe
//
//  Created by Ben Guo on 5/22/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (StripeInternal)

+ (NSError *)stp_ephemeralKeyDecodingError;

@end
