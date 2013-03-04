//
//  TCViewController.m
//  TreatCar
//
//  Created by Saikat Chakrabarti on 11/1/12.
//  Copyright (c) 2012 Stripe. All rights reserved.
//

#import "TCViewController.h"
#import "Stripe.h"
#define STRIPE_PUBLIC_KEY @"pk_test_czwzkTp2tactuLOEOqbMTRzG"

@interface TCViewController ()
- (IBAction)orderButton:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *numberTextField;
@property (weak, nonatomic) IBOutlet UITextField *expMonthTextField;
@property (weak, nonatomic) IBOutlet UITextField *expYearTextField;
@property (weak, nonatomic) IBOutlet UITextField *cvcTextField;
@property (weak, nonatomic) IBOutlet UILabel *cardErrorLabel;

- (SEL)textFieldSelectorForCardProperty:(NSString *)property;
- (void)handleValidationError:(NSError *)error;
- (void)handleStripeError:(NSError *)error;
- (void)resetErrors;
@end

@implementation TCViewController

#pragma mark - View lifecycle

- (SEL)textFieldSelectorForCardProperty:(NSString *)property
{
    NSString *fieldName = [property stringByAppendingString:@"TextField"];
    SEL textFieldSelector = NSSelectorFromString(fieldName);

    if ([self respondsToSelector:textFieldSelector])
        return textFieldSelector;
    else
        return nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)handleValidationError:(NSError *)error
{
    if ([error domain] == StripeDomain)
    {
        if ([[self.cardErrorLabel text] isEqualToString:@""])
            [self.cardErrorLabel setText:[error localizedDescription]];
        if ([error code] == STPCardError)
        {
            NSString *errorParameter = [[error userInfo] valueForKey:STPErrorParameterKey];
            if (errorParameter)
            {
                SEL textFieldSelector = [self textFieldSelectorForCardProperty:errorParameter];
                if (textFieldSelector)
                {
                    [[self performSelector:textFieldSelector] setBackgroundColor:[UIColor redColor]];
                }
            }
        }
    }
}

- (void)resetErrors
{
    [self.cardErrorLabel setText:@""];
    [self.numberTextField setBackgroundColor:[UIColor whiteColor]];
    [self.expMonthTextField setBackgroundColor:[UIColor whiteColor]];
    [self.expYearTextField setBackgroundColor:[UIColor whiteColor]];
    [self.cvcTextField setBackgroundColor:[UIColor whiteColor]];
}

- (void)handleStripeError:(NSError *)error
{
    NSLog(@"Error code: %d", [error code]);
    NSLog(@"User facing error message: %@", [error localizedDescription]);
    NSLog(@"Error parameter: %@", [[error userInfo] valueForKey:STPErrorParameterKey]);
    NSLog(@"Developer facing error message: %@", [[error userInfo] valueForKey:STPErrorMessageKey]);
    NSLog(@"Card error code: %@", [[error userInfo] valueForKey:STPCardErrorCodeKey]);
}

- (IBAction)orderButton:(id)sender
{
    [self resetErrors];

    STPCard *card = [[STPCard alloc] init];
    card.number = self.numberTextField.text;
    card.expMonth = [self.expMonthTextField.text integerValue];
    card.expYear = [self.expYearTextField.text integerValue];
    card.cvc = self.cvcTextField.text;
    
    NSError *overallError = nil;
    
    [card validateCardReturningError:&overallError];
    if (overallError)
        return [self handleValidationError:overallError];

    [Stripe createTokenWithCard:card
                 publishableKey:STRIPE_PUBLIC_KEY
                     completion:^(STPToken *token, NSError *error) {
                    if (error) {
                        [self handleStripeError:error];
                    } else {
        
                        NSLog(@"Created token with ID: %@", token.tokenId);
                        // Send token to server...
                    }
                }];
}

@end
#pragma clang diagnostic pop