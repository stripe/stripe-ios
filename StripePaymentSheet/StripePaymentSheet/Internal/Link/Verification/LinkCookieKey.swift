//
//  LinkCookieKey.swift
//  StripeiOS
//
//  Created by Ramon Torres on 8/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

enum LinkCookieKey: String {
    case session = "com.stripe.pay_sid"
    case lastLogoutEmail = "com.stripe.link_account"
    case lastSignupEmail = "com.stripe.link.last_signup_email"
}
