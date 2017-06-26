//
//  Config.swift
//  Stripe iOS Example (Simple)
//
//  Created by Tara Teich on 6/15/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit

class Config: NSObject {
    static let shared = Config()
    
    /** 
     1) To get started with this demo, first head to
        https://dashboard.stripe.com/account/apikeys
        and copy your "Test Publishable Key" (it looks like pk_test_abcdef)
        into the line below.
    */
    let stripePublishableKey = ""

    /*
     2) Next head to
        https://github.com/stripe/example-ios-backend ,
        click "Deploy to Heroku", and follow the instructions
        (don't worry, it's free). Replace nil on the line below with your
        Heroku URL (it looks like https://blazing-sunrise-1234.herokuapp.com ).
     */
    let backendBaseURL: String? = nil

    /*
     3) Optionally, to enable Apple Pay, follow the instructions at
        https://stripe.com/docs/mobile/apple-pay
        to create an Apple Merchant ID. Replace nil on the line below with it
        (it looks like merchant.com.yourappname).
     */
    let appleMerchantID: String? = nil
    
    // These values will be shown to the user when they purchase with Apple Pay.
    let companyName = "Emoji Apparel"
    let paymentCurrency = "usd"
}
