//
//  STDSException+Internal.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSException.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSException (Internal)

+ (instancetype)exceptionWithMessage:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
