//
//  Constants.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/22/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "Constants.h"

// This can be found at https://dashboard.stripe.com/account/apikeys
NSString *const StripePublishableKey = @"pk_test_e5Bb6ThQvHNaTwzfF9Z5NE3j";

// To set this up, check out https://github.com/stripe/example-ios-backend/tree/v18.1.0
// This should be in the format https://my-shiny-backend.herokuapp.com
NSString *const BackendBaseURL = @"https://cam-empty-example-backend.herokuapp.com/";

// To learn how to obtain an Apple Merchant ID, head to https://stripe.com/docs/mobile/apple-pay
NSString *const AppleMerchantId = @"merchant.com.stripe.apple-pay-qualifications"; // TODO: replace nil with your own value
