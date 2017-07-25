//
//  NSError+StripePrivate.h
//  Stripe
//
//  Created by Ben Guo on 5/22/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (StripePrivate)

+ (NSError *)stp_ephemeralKeyDecodingError;

@end
