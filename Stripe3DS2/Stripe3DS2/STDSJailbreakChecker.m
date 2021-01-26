//
//  STDSJailbreakChecker.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 4/8/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSJailbreakChecker.h"

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@implementation STDSJailbreakChecker

// This was implemented under the following guidance: https://medium.com/@pinmadhon/how-to-check-your-app-is-installed-on-a-jailbroken-device-67fa0170cf56
+ (BOOL)isJailbroken {
    
    // Check for existence of files that are common for jailbroken devices
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"] ||
        [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/MobileSubstrate.dylib"]) {
        return YES;
    }
    
    return NO;
}

@end

NS_ASSUME_NONNULL_END
