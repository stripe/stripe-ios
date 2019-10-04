//
//  Constants.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/22/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "Constants.h"

// This can be found at https://dashboard.stripe.com/account/apikeys
NSString *const StripePublishableKey = @"pk_test_JBVAMwnBuzCdmsgN34jfxbU700LRiPqVit"; // TODO: replace nil with your own value

// To set this up, check out https://github.com/stripe/example-ios-backend/tree/v17.0.0
// This should be in the format https://my-shiny-backend.herokuapp.com
NSString *const BackendBaseURL = @"https://yuki-test-15.herokuapp.com/"; // TODO: replace nil with your own value

// To learn how to obtain an Apple Merchant ID, head to https://stripe.com/docs/mobile/apple-pay
NSString *const AppleMerchantId = @"merchant.com.stripe.apple-pay-qualifications";
