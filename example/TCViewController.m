//
//  TCViewController.m
//  TreatCar
//
//  Created by Saikat Chakrabarti on 11/1/12.
//  Copyright (c) 2012 Stripe. All rights reserved.
//

#import "TCViewController.h"
#import "Stripe.h"

@interface TCViewController ()
@property (weak, nonatomic) IBOutlet UITextField *treatCarTextField;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (copy) NSNumber *price;
- (IBAction)orderButton:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *numberTextField;
@property (weak, nonatomic) IBOutlet UITextField *expMonthTextField;
@property (weak, nonatomic) IBOutlet UITextField *expYearTextField;
@property (weak, nonatomic) IBOutlet UITextField *cvcTextField;
@property (weak, nonatomic) IBOutlet UILabel *cardErrorLabel;

- (SEL)textFieldSelectorForCardProperty:(NSString *)property;
- (void)handleStripeError:(NSError *)error;
- (void)resetErrors;
@end

@implementation TCViewController
@synthesize treatCarTextField;
@synthesize priceLabel;

#pragma mark - View lifecycle

- (void)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.treatCarTextField)
    {
        NSInteger amount = self.treatCarTextField.text.integerValue;
        self.price = [NSNumber numberWithInt:amount * 15];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        self.priceLabel.text = [NSString stringWithFormat:@"$%@.00", [formatter stringFromNumber:self.price]];
    }
    [textField resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (SEL)textFieldSelectorForCardProperty:(NSString *)property
{
    NSString *fieldName = [property stringByAppendingString:@"TextField"];
    SEL textFieldSelector = NSSelectorFromString(fieldName);

    if ([self respondsToSelector:textFieldSelector])
        return textFieldSelector;
    else
        return NULL;
}

// We use two performSelectors below, both of which are safe, so we add this here to suppress the warning for this one call.  From http://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)handleStripeError:(NSError *)error
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

- (IBAction)orderButton:(id)sender
{
    [self resetErrors];
    STPCard *card = [[STPCard alloc] init];
    NSArray *propertiesToValidate = [NSArray arrayWithObjects:@"number", @"expMonth", @"expYear", @"cvc", nil];

    BOOL didValidate = YES;
    for (NSString *property in propertiesToValidate)
    {
        SEL textFieldSelector = [self textFieldSelectorForCardProperty:property];
        if (textFieldSelector)
        {
            NSString *textValue = [[self performSelector:textFieldSelector] performSelector:@selector(text)];
            [card setValue:textValue forKey:property];
/*
            // If you want to do property-by-property validation, uncomment this block.  The call to "validateCardReturningError" below, however, is enough to catch validation errors on the card itself
            NSError *validationError = NULL;

            if (![card validateValue:&textValue forKey:property error:&validationError])
            {
                [self handleStripeError:(validationError)];
                didValidate = NO;
            }
 */
            
        }
        
    }

    if (didValidate)
    {
        NSError *overallError = NULL;
        [card validateCardReturningError:&overallError];
        if (overallError)
            [self handleStripeError:overallError];
        else
        {
            [Stripe createTokenWithCard:card completionHandler:^(STPToken *token, NSError *error)
             {
                 if (error)
                 {
                     NSLog(@"Error code: %d", [error code]);
                     NSLog(@"User facing error message: %@", [error localizedDescription]);
                     NSLog(@"Error parameter: %@", [[error userInfo] valueForKey:STPErrorParameterKey]);
                     NSLog(@"Developer facing error message: %@", [[error userInfo] valueForKey:STPErrorMessageKey]);
                     NSLog(@"Card error code: %@", [[error userInfo] valueForKey:STPCardErrorCodeKey]);
                 }
                 NSLog(@"Created token with ID: %@", token.tokenId);
             }
             ];
        }
    }
}
@end
#pragma clang diagnostic pop