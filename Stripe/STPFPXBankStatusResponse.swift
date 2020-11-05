//
//  STPFPXBankStatusResponse.swift
//  Stripe
//
//  Created by David Estes on 10/21/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

class STPFPXBankStatusResponse: NSObject, STPAPIResponseDecodable {
  func bankBrandIsOnline(_ bankBrand: STPFPXBankBrand) -> Bool {
    let bankCode = STPFPXBank.bankCodeFrom(bankBrand, false)
    let bankStatus = bankList?[bankCode ?? ""]
    if bankCode != nil && bankStatus != nil {
      return bankStatus?.boolValue ?? false
    }
    // This status endpoint isn't reliable. If we don't know this bank's status, default to online.
    // The worst that will happen here is that the user ends up at their bank's "Down For Maintenance" page when checking out.
    return true
  }

  private var bankList: [String: NSNumber]?
  private(set) var allResponseFields: [AnyHashable: Any] = [:]

  required internal override init() {
    super.init()
  }

  class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    let statusResponse = self.init()
    statusResponse.bankList =
      dict.stp_dictionary(forKey: "parsed_bank_status") as? [String: NSNumber]
    statusResponse.allResponseFields = dict as! [AnyHashable: Any]

    return statusResponse
  }
}
