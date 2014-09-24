//
//  Constants.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/22/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "Constants.h"

#warning Replace these with your own values and then remove this warning. Make sure to replace the values in StripeExample/Parse/config/global.json as well if you want to use Parse.

// This can be found at https://dashboard.stripe.com/account/apikeys
NSString * const StripePublishableKey = @"pk_YT1CEhhujd0bklb2KGQZiaL3iTzj3"; // TODO: replace nil with your own value
BOOL const StripeTestMode = TRUE; // TODO: replace with FALSE for production/live

// These can be found at https://www.parse.com/apps/stripe-test/edit#app_keys
NSString * const ParseApplicationId = nil; // TODO: replace nil with your own value
NSString * const ParseClientKey = nil; // TODO: replace nil with your own value

@implementation Constants
@end
