//
//  PKCardCVCDelegate.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PKCardCVCDelegate.h"

@implementation PKCardCVCDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [textField.text stringByReplacingCharactersInRange:range withString:replacementString];
    PKCardCVC *cardCVC = [PKCardCVC cardCVCWithString:resultString];
    
    // Restrict length
    if ( ![cardCVC isPartiallyValid] ) return NO;
    
    // Strip non-digits
    textField.text = [cardCVC string];
    
    return NO;
}

@end
