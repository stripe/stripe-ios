//
//  PKCardNumberDelegate.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PKCardNumberDelegate.h"

@implementation PKCardNumberDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString   = [textField.text stringByReplacingCharactersInRange:range withString:replacementString];
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:resultString];
    
    if ( ![cardNumber isPartiallyValid] ) return NO;
    
    if (replacementString.length > 0) {
        textField.text = [cardNumber formattedStringWithTrail];
    } else {
        textField.text = [cardNumber formattedString];
    }
    
    return NO;
}

@end
