//
//  STPLocalizationUtils+STPTestAdditions.h
//  Stripe
//
//  Created by Brian Dorfman on 10/31/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPLocalizationUtils.h"

@interface STPLocalizationUtils (TestAdditions)
+ (void)overrideLanguageTo:(nullable NSString *)string;
@end
