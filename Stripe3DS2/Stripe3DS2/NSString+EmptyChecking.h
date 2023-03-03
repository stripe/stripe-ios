//
//  NSString+EmptyChecking.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/4/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EmptyChecking)

+ (BOOL)_stds_isStringEmpty:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
