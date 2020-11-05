//
//  STPIssuingCardPin.swift
//  Stripe
//
//  Created by Arnaud Cavailhez on 4/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Information related to a Stripe Issuing card, including the PIN
public class STPIssuingCardPin: NSObject {
  /// The PIN for the card
  @objc public let pin: String?
  /// If the PIN failed to be created, this error might be present
  @objc public let error: [AnyHashable: Any]?
  @objc public let allResponseFields: [AnyHashable: Any]

  convenience override init() {
    self.init(pin: nil, error: nil, allResponseFields: [:])
  }

  private init(pin: String?, error: [AnyHashable: Any]?, allResponseFields: [AnyHashable: Any]) {
    self.pin = pin
    self.error = error
    self.allResponseFields = allResponseFields
    super.init()
  }
}

extension STPIssuingCardPin: STPAPIResponseDecodable {
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let dict = response else {
      return nil
    }

    if let error = dict["error"] as? [AnyHashable: Any] {
      // Return object to be able to read errors
      let pinObject = STPIssuingCardPin(pin: nil, error: error, allResponseFields: dict)
      return pinObject as? Self
    }

    // required fields
    guard let pin = dict["pin"] as? String else {
      return nil
    }

    let pinObject = STPIssuingCardPin(pin: pin, error: nil, allResponseFields: dict)
    return pinObject as? Self
  }
}
