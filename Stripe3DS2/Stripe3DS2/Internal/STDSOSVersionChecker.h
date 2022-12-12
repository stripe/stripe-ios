//
//  STDSOSVersionChecker.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 4/8/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STDSOSVersionChecker : NSObject

+ (BOOL)isSupportedOSVersion;

@end

NS_ASSUME_NONNULL_END
