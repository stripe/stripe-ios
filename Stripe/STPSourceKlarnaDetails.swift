//
//  STPSourceKlarnaDetails.swift
//  Stripe
//
//  Created by David Estes on 11/19/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Details of a Klarna source.
public class STPSourceKlarnaDetails: NSObject, STPAPIResponseDecodable {
  /// The Klarna-specific client token. This may be used with the Klarna SDK.
  /// - seealso: https://developers.klarna.com/documentation/in-app/ios/steps-klarna-payments-native/#initialization
  @objc public private(set) var clientToken: String?
  /// The ISO-3166 2-letter country code of the customer's location.
  @objc public private(set) var purchaseCountry: String?
  private(set) public var allResponseFields: [AnyHashable: Any] = [:]

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      String(format: "%@: %p", NSStringFromClass(STPSourceKlarnaDetails.self), self),
      "clientToken = \(clientToken ?? "")",
      "purchaseCountry = \(purchaseCountry ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPAPIResponseDecodable
  override required init() {
    super.init()
  }

  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    let details = self.init()
    details.clientToken = dict.stp_string(forKey: "client_token")
    details.purchaseCountry = dict.stp_string(forKey: "purchase_country")
    details.allResponseFields = response
    return details
  }
}
