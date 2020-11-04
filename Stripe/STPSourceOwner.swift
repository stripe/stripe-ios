//
//  STPSourceOwner.swift
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// Information about a source's owner.
public class STPSourceOwner: NSObject, STPAPIResponseDecodable {
  override required init() {
    super.init()
  }

  /// Owner's address.
  @objc public private(set) var address: STPAddress?
  /// Owner's email address.
  @objc public private(set) var email: String?
  /// Owner's full name.
  @objc public private(set) var name: String?
  /// Owner's phone number.
  @objc public private(set) var phone: String?
  /// Verified owner's address.
  @objc public private(set) var verifiedAddress: STPAddress?
  /// Verified owner's email address.
  @objc public private(set) var verifiedEmail: String?
  /// Verified owner's full name.
  @objc public private(set) var verifiedName: String?
  /// Verified owner's phone number.
  @objc public private(set) var verifiedPhone: String?
  @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

  // MARK: - STPAPIResponseDecodable
  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    let owner = self.init()
    owner.allResponseFields = response
    let rawAddress = dict.stp_dictionary(forKey: "address")
    if let rawAddress = rawAddress {
      owner.address = STPAddress.decodedObject(fromAPIResponse: rawAddress)
    }
    owner.email = dict.stp_string(forKey: "email")
    owner.name = dict.stp_string(forKey: "name")
    owner.phone = dict.stp_string(forKey: "phone")
    let rawVerifiedAddress = dict.stp_dictionary(forKey: "verified_address")
    if let rawVerifiedAddress = rawVerifiedAddress {
      owner.verifiedAddress = STPAddress.decodedObject(fromAPIResponse: rawVerifiedAddress)
    }
    owner.verifiedEmail = dict.stp_string(forKey: "verified_email")
    owner.verifiedName = dict.stp_string(forKey: "verified_name")
    owner.verifiedPhone = dict.stp_string(forKey: "verified_phone")
    return owner
  }
}
