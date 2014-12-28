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

@interface STPColorUtils : NSObject

+ (BOOL)colorIsLight:(STP_COLOR_CLASS *)color;

+ (STP_COLOR_CLASS *)colorForHexCode:(NSString *)hexCode;
+ (NSString *)hexCodeForColor:(STP_COLOR_CLASS *)color;

@end
