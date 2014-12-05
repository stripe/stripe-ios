//
//  STPColorUtils.h
//  Stripe
//
//  Created by Jack Flintermann on 11/3/14.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface STPColorUtils : NSObject

+ (BOOL)colorIsLight:(UIColor *)color;

+ (UIColor *)colorForHexCode:(NSString *)hexCode;
+ (NSString *)hexCodeForColor:(UIColor *)color;

@end
