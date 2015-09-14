//
//  STPColorUtils.h
//  Stripe
//
//  Created by Jack Flintermann on 11/3/14.
//
//

#import <Foundation/Foundation.h>
#import "TargetConditionals.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define STP_COLOR_CLASS UIColor
#else
#import <AppKit/AppKit.h>
#define STP_COLOR_CLASS NSColor
#endif



@interface STPColorUtils : NSObject

+ (BOOL)colorIsLight:(nonnull STP_COLOR_CLASS *)color;

+ (nonnull STP_COLOR_CLASS *)colorForHexCode:(nonnull NSString *)hexCode;
+ (nonnull NSString *)hexCodeForColor:(nonnull STP_COLOR_CLASS *)color;

@end
