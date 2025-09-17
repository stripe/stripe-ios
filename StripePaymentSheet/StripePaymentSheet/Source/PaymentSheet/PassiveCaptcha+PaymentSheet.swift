//
//  PassiveCaptcha+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 9/11/25.
//

 import Foundation
 @_spi(STP) import StripePayments

 extension PassiveCaptchaChallenge {
     /// Fetches a token for the given payment option, returning nil for payment options that don't need to fetch the token now
     /// - Parameter paymentOption: The payment option to check
     /// - Returns: The captcha token, or nil if the payment option is .saved or if token fetch fails
     func fetchToken(for paymentOption: PaymentOption?) async -> String? {
         // HCaptcha initial load takes several seconds, which disrupts user experience if paying with a saved pm or ApplePay since there isn't anything for the user to input
         // Also, the goal is to prevent card-testing, which doesn't happen with these scenarios
         switch paymentOption {
         case .applePay, .saved:
             return nil
         // Link wallet options come from FlowController or Embedded when Link is selected and confirmed. When it's a wallet Link option, it pulls up the PayWith(Native)LinkController, which calls confirm from there as a withPaymentDetails Link option.
         // If we fetch, then it delays pulling up the LinkController. We can return nil here and fetch the token from within PayWith(Native)LinkController's confirmation so the token isn't fetched until the user confirms from the LinkController
         case .link(option: .wallet):
             return nil
         default:
             return await fetchToken()
         }
     }
 }
