//
//  PTKComponent.h
//  Stripe
//
//  Created by Phil Cohen on 12/18/13.
//
//

#import <Foundation/Foundation.h>

// Abstract class; represents a component of a credit card.
@interface PTKComponent : NSObject

- (id)initWithString:(NSString *)string;
- (NSString *)string;
- (NSString *)formattedString;
- (BOOL)isValid;

// Whether the value is valid so far, even if incomplete (useful for as-you-type validation).
- (BOOL)isPartiallyValid;

// The formatted value with trailing spaces inserted as needed (such as after groups in the credit card number).
- (NSString *)formattedStringWithTrail;

@end
