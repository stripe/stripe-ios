//
//  STPPaymentContextAmountModel.swift
//  Stripe
//
//  Created by Brian Dorfman on 8/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

/// Internal model for STPPaymentContext's `paymentAmount` and
/// `paymentSummaryItems` properties.
class STPPaymentContextAmountModel: NSObject {
  private var paymentAmount = 0
  private var paymentSummaryItems: [PKPaymentSummaryItem]?

  init(amount paymentAmount: Int) {
    super.init()
    self.paymentAmount = paymentAmount
    paymentSummaryItems = nil
  }

  init(paymentSummaryItems: [PKPaymentSummaryItem]?) {
    super.init()
    paymentAmount = 0
    self.paymentSummaryItems = paymentSummaryItems
  }

  func paymentAmount(withCurrency currency: String?, shippingMethod: PKShippingMethod?) -> Int {
    let shippingAmount =
      ((shippingMethod != nil) ? shippingMethod?.amount.stp_amount(withCurrency: currency) : 0) ?? 0
    if paymentSummaryItems == nil {
      return paymentAmount + shippingAmount
    } else {
      let lastItem = paymentSummaryItems?.last
      return (lastItem?.amount.stp_amount(withCurrency: currency) ?? 0) + shippingAmount
    }
  }

  func paymentSummaryItems(
    withCurrency currency: String?,
    companyName: String?,
    shippingMethod: PKShippingMethod?
  ) -> [PKPaymentSummaryItem]? {
    var shippingItem: PKPaymentSummaryItem?
    if let shippingMethod = shippingMethod {
      shippingItem = PKPaymentSummaryItem(
        label: shippingMethod.label,
        amount: shippingMethod.amount)
    }
    if paymentSummaryItems == nil {
      let shippingAmount = shippingMethod?.amount.stp_amount(withCurrency: currency) ?? 0
      let total = NSDecimalNumber.stp_decimalNumber(
        withAmount: paymentAmount + shippingAmount,
        currency: currency)
      var totalItem: PKPaymentSummaryItem?
      if let total = total {
        totalItem = PKPaymentSummaryItem(
          label: companyName ?? "",
          amount: total)
      }
      var items = [totalItem]
      if let shippingItem = shippingItem {
        items.insert(shippingItem, at: 0)
      }
      return items.compactMap { $0 }
    } else {
      if (paymentSummaryItems?.count ?? 0) > 0 && shippingItem != nil {
        var items = paymentSummaryItems
        let origTotalItem = items?.last
        var newTotal: NSDecimalNumber?
        if let amount1 = shippingItem?.amount {
          newTotal = origTotalItem?.amount.adding(amount1)
        }
        var totalItem: PKPaymentSummaryItem?
        if let newTotal = newTotal {
          totalItem = PKPaymentSummaryItem(label: origTotalItem?.label ?? "", amount: newTotal)
        }
        items?.removeLast()
        if let items = items {
          return items + [shippingItem, totalItem].compactMap { $0 }
        }
        return nil
      } else {
        return paymentSummaryItems
      }
    }
  }
}
