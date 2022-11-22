//
//  STDSSimulatorChecker.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 4/8/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSSimulatorChecker.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSSimulatorChecker

+ (BOOL)isRunningOnSimulator {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

@end

NS_ASSUME_NONNULL_END
