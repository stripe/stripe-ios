//
//  STPUtils.h
//  Stripe
//
//  Created by Ray Morgan on 7/11/14.
//
//

#import <Foundation/Foundation.h>

@interface STPUtils : NSObject

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input;
+ (NSString *)stringByURLEncoding:(NSString *)string;

@end
