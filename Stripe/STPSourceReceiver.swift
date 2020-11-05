//
//  STPSourceReceiver.swift
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// Information related to a source's receiver flow.
public class STPSourceReceiver: NSObject, STPAPIResponseDecodable {
  /// The address of the receiver source. This is the value that should be communicated to the customer to send their funds to.
  @objc public private(set) var address: String?
  /// The total amount charged by you.
  @objc public private(set) var amountCharged: NSNumber?
  /// The total amount received by the receiver source.
  @objc public private(set) var amountReceived: NSNumber?
  /// The total amount that was returned to the customer.
  @objc public private(set) var amountReturned: NSNumber?
  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPSourceReceiver.self), self),
      // Details (alphabetical)
      "address = \(((address) != nil ? "<redacted>" : nil) ?? "")",
      "amountCharged = \(amountCharged ?? 0)",
      "amountReceived = \(amountReceived ?? 0)",
      "amountReturned = \(amountReturned ?? 0)",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPAPIResponseDecodable
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    // required fields
    let address = dict.stp_string(forKey: "address")
    if address == nil {
      return nil
    }

    let receiver = self.init()
    receiver.allResponseFields = response
    receiver.address = address
    receiver.amountCharged = dict.stp_number(forKey: "amount_charged")
    receiver.amountReceived = dict.stp_number(forKey: "amount_received")
    receiver.amountReturned = dict.stp_number(forKey: "amount_returned")
    return receiver
  }

  override required init() {
    super.init()
  }
}
