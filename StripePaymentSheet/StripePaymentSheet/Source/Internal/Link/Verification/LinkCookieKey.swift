//
//  LinkCookieKey.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 8/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

enum LinkCookieKey: String {
    case lastLogoutEmail = "com.stripe.link_account"
    case lastPMLast4 = "com.stripe.link.last_pm_last4"
    case lastPMBrand = "com.stripe.link.last_pm_brand"
    case hasUsedLink = "com.stripe.link.has_used_link"
    case lastSignupEmail = "com.stripe.link.last_signup_email"
}
