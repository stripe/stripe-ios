//
//  STPBECSDebitAccountNumberValidator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

class STPBECSDebitAccountNumberValidator: STPNumericStringValidator {
  class func validationState(
    forText text: String,
    withBSBNumber bsbNumber: String?,
    completeOnMaxLengthOnly: Bool
  ) -> STPTextValidationState {
    let numericText = self.sanitizedNumericString(for: text)
    if numericText.count == 0 {
      return .empty
    } else {
      let accountLengthRange = self._accountNumberLengthRange(forBSBNumber: bsbNumber)
      if numericText.count < accountLengthRange.location {
        return .incomplete
      } else if !completeOnMaxLengthOnly
        && (NSLocationInRange(numericText.count, accountLengthRange)
          || numericText.count == NSMaxRange(accountLengthRange))
      {
        return .complete
      } else if completeOnMaxLengthOnly && numericText.count == NSMaxRange(accountLengthRange) {
        return .complete
      } else if completeOnMaxLengthOnly && NSLocationInRange(numericText.count, accountLengthRange)
      {
        return .incomplete
      } else {
        return .invalid
      }
    }
  }

  class func formattedSanitizedText(from string: String, withBSBNumber bsbNumber: String?)
    -> String?
  {
    let accountLengthRange = self._accountNumberLengthRange(forBSBNumber: bsbNumber)
    return self.sanitizedNumericString(for: string).stp_safeSubstring(
      to: NSMaxRange(accountLengthRange))
  }

  class func _accountNumberLengthRange(forBSBNumber bsbNumber: String?) -> NSRange {
    // For a few banks we know how many digits the account number *should* have,
    // but we still allow users to enter up to 9 digits just in case some bank
    // decides to add more digits on.
    let firstTwo = bsbNumber?.stp_safeSubstring(to: 2)
    if firstTwo == "00" {
      // Stripe
      return NSRange(location: 9, length: 0)
    } else if firstTwo == "06" {
      // Commonwealth/CBA: 8 digits https://www.commbank.com.au/support.digital-banking.confirm-account-number-digits.html
      return NSRange(location: 8, length: 1)
    } else if (firstTwo == "03") || (firstTwo == "73") {
      // Westpac/WBC: 6 digits
      return NSRange(location: 6, length: 3)
    } else if firstTwo == "01" {
      // ANZ: 9 digits https://www.anz.com.au/support/help/
      return NSRange(location: 9, length: 0)
    } else if firstTwo == "08" {
      // NAB: 9 digits https://www.nab.com.au/business/accounts/business-accounts-online-application-help
      return NSRange(location: 9, length: 0)
    } else if firstTwo == "80" {
      // Cuscal: 4 digits(?) https://groups.google.com/a/stripe.com/d/msg/au-becs-debits-archive/EERH5iITxQ4/Ksb84bV1AQAJ
      return NSRange(location: 4, length: 5)
    } else {
      // Default 5-9 digits
      return NSRange(location: 5, length: 4)
    }
  }
}
