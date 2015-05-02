//
//  STPColorUtils.h
//  Stripe
//
//  Created by Jack Flintermann on 11/3/14.
//
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define STP_COLOR_CLASS UIColor
#else
#import <AppKit/AppKit.h>
#define STP_COLOR_CLASS NSColor
#endif

#import "STPNullabilityMacros.h"

@interface STPColorUtils : NSObject

+ (BOOL)colorIsLight:(stp_nonnull STP_COLOR_CLASS *)color;

+ (stp_nonnull STP_COLOR_CLASS *)colorForHexCode:(stp_nonnull NSString *)hexCode;
+ (stp_nonnull NSString *)hexCodeForColor:(stp_nonnull STP_COLOR_CLASS *)color;

@end
