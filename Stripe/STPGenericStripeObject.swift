//
//  STPGenericStripeObject.swift
//  Stripe
//
//  Created by Daniel Jackson on 7/11/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// Generic decodable Stripe object. It only has an `id`
/// `STPAPIRequest` expects to be able to parse an object out of the result, otherwise
/// it considers the request to have failed.
/// This primarily exists to handle the response to calls like these:
/// - https://stripe.com/docs/api#delete_card + https://stripe.com/docs/api#detach_source
/// - https://stripe.com/docs/api#customer_delete_bank_account
/// This will probably never be useful to expose publicly, the caller probably already has the
/// id.
class STPGenericStripeObject: NSObject, STPAPIResponseDecodable {
  /// The stripe id of this object.
  @objc public private(set) var stripeId: String?
  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  required override init() {
    super.init()
  }

  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary
    guard let stripeId = dict.stp_string(forKey: "id") else {
      return nil
    }

    let source = self.init()

    source.stripeId = stripeId
    source.allResponseFields = dict as! [AnyHashable: Any]

    return source
  }
}
