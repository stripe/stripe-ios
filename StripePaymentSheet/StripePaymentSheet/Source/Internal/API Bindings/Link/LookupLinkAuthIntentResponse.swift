//
//  LookupLinkAuthIntentResponse.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/23/25.
//

import Foundation

struct LookupLinkAuthIntentResponse {
    let linkAccount: PaymentSheetLinkAccount
    let consentViewModel: LinkConsentViewModel?
}
