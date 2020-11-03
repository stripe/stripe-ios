//
//  STPSourceRedirect.swift
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// Redirect status types for a Source.
@objc
public enum STPSourceRedirectStatus: Int {
  /// The redirect is pending.
  case pending
  /// The redirect has succeeded.
  case succeeded
  /// The redirect has failed.
  case failed
  /// The redirect should not be used.
  case notRequired
  /// The state of the redirect is unknown.
  case unknown
}

/// Information related to a source's redirect flow.
public class STPSourceRedirect: NSObject, STPAPIResponseDecodable {
  /// The URL you provide to redirect the customer to after they authenticated their payment.
  @objc public private(set) var returnURL: URL
  /// The status of the redirect.
  @objc public private(set) var status: STPSourceRedirectStatus = .unknown
  /// The URL provided to you to redirect a customer to as part of a redirect authentication flow.
  @objc public private(set) var url: URL
  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  // MARK: - STPSourceRedirectStatus
  class func stringToStatusMapping() -> [String: NSNumber] {
    return [
      "pending": NSNumber(value: STPSourceRedirectStatus.pending.rawValue),
      "succeeded": NSNumber(value: STPSourceRedirectStatus.succeeded.rawValue),
      "failed": NSNumber(value: STPSourceRedirectStatus.failed.rawValue),
      "not_required": NSNumber(value: STPSourceRedirectStatus.notRequired.rawValue),
    ]
  }

  @objc(statusFromString:)
  class func status(from string: String) -> STPSourceRedirectStatus {
    let key = string.lowercased()
    let statusNumber = self.stringToStatusMapping()[key]

    if let statusNumber = statusNumber {
      return (STPSourceRedirectStatus(rawValue: statusNumber.intValue))!
    }

    return .unknown
  }

  @objc(stringFromStatus:)
  class func string(from status: STPSourceRedirectStatus) -> String? {
    return
      (self.stringToStatusMapping() as NSDictionary).allKeys(for: NSNumber(value: status.rawValue))
      .first as? String
  }

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPSourceRedirect.self), self),
      // Details (alphabetical)
      "returnURL = \(String(describing: returnURL))",
      "status = \((STPSourceRedirect.string(from: status)) ?? "unknown")",
      "url = \(String(describing: url))",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPAPIResponseDecodable
  required init(returnURL: URL, url: URL) {
    self.returnURL = returnURL
    self.url = url
    super.init()
  }

  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    // required fields
    guard let returnURL = dict.stp_url(forKey: "return_url"),
      let rawStatus = dict.stp_string(forKey: "status"),
      let url = dict.stp_url(forKey: "url") else {
      return nil
    }

    let redirect = self.init(returnURL: returnURL, url: url)
    redirect.allResponseFields = response
    redirect.returnURL = returnURL
    redirect.status = self.status(from: rawStatus)
    redirect.url = url
    return redirect
  }
}
