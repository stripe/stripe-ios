//
//  STDSIntegrityChecker.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 4/8/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSIntegrityChecker.h"
#import "Stripe3DS2.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSIntegrityChecker

+ (BOOL)SDKIntegrityIsValid {
    
    if (NSClassFromString(@"STDSIntegrityChecker") == [STDSIntegrityChecker class] &&
        NSClassFromString(@"STDSConfigParameters") == [STDSConfigParameters class] &&
        NSClassFromString(@"STDSThreeDS2Service") == [STDSThreeDS2Service class] &&
        NSClassFromString(@"STDSUICustomization") == [STDSUICustomization class] &&
        NSClassFromString(@"STDSWarning") == [STDSWarning class] &&
        NSClassFromString(@"STDSAlreadyInitializedException") == [STDSAlreadyInitializedException class] &&
        NSClassFromString(@"STDSNotInitializedException") == [STDSNotInitializedException class] &&
        NSClassFromString(@"STDSRuntimeException") == [STDSRuntimeException class] &&
        NSClassFromString(@"STDSErrorMessage") == [STDSErrorMessage class] &&
        NSClassFromString(@"STDSRuntimeErrorEvent") == [STDSRuntimeErrorEvent class] &&
        NSClassFromString(@"STDSProtocolErrorEvent") == [STDSProtocolErrorEvent class] &&
        NSClassFromString(@"STDSAuthenticationRequestParameters") == [STDSAuthenticationRequestParameters class] &&
        NSClassFromString(@"STDSChallengeParameters") == [STDSChallengeParameters class] &&
        NSClassFromString(@"STDSCompletionEvent") == [STDSCompletionEvent class] &&
        NSClassFromString(@"STDSTransaction") == [STDSTransaction class]) {
        return YES;
    }
    
    return NO;
}

@end

NS_ASSUME_NONNULL_END
