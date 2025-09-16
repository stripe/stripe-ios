//
//  PassiveCaptcha+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 9/11/25.
//

 import Foundation
 @_spi(STP) import StripePayments

 extension PassiveCaptchaChallenge {
     /// Fetches a token for the given payment option, returning nil for saved payment methods
     /// - Parameter paymentOption: The payment option to check
     /// - Returns: The captcha token, or nil if the payment option is .saved or if token fetch fails
     func fetchToken(for paymentOption: PaymentOption?) async -> String? {
         // HCaptcha initial load takes several seconds, which disrupts user experience if paying with a saved pm or ApplePay since there isn't anything for the user to input
         // Also, the goal is to prevent card-testing, which doesn't happen with these scenarios
         switch paymentOption {
         case .applePay, .saved, .link(option: .wallet):
             return nil
         default:
             return await fetchToken()
         }
     }
 }
