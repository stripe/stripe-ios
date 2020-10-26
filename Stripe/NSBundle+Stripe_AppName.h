//
//  NSBundle+Stripe_AppName.h
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (Stripe_AppName)

+ (nullable NSString*)stp_applicationName;
+ (nullable NSString*)stp_applicationVersion;

@end

void linkNSBundleAppNameCategory(void);
