//
//  NSString+EmptyChecking.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/4/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "NSString+EmptyChecking.h"

@implementation NSString (EmptyChecking)

+ (BOOL)_stds_isStringEmpty:(NSString *)string {
    if (string.length == 0) {
        return YES;
    }
    
    if(![string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length) {
        return YES;
    }
    
    return NO;
}

@end
