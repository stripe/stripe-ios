//
//  STPIntentActionAlipayHandleRedirect.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains instructions for authenticating a payment by redirecting your customer to Alipay App or website.
/// You cannot directly instantiate an `STPPaymentIntentActionAlipayHandleRedirect`.
public class STPIntentActionAlipayHandleRedirect: NSObject {

  /// The native URL you must redirect your customer to in order to authenticate the payment.
  @objc public let nativeURL: URL?

  /// If the customer does not exit their browser while authenticating, they will be redirected to this specified URL after completion.
  @objc public let returnURL: URL

  /// The URL you must redirect your customer to in order to authenticate the payment.
  @objc public let url: URL

  /// :nodoc:
  @objc public let allResponseFields: [AnyHashable: Any]

  /// :nodoc:
  @objc public override var description: String {
    let props: [String] = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPIntentActionAlipayHandleRedirect.self), self),
      // RedirectToURL details (alphabetical)
      "nativeURL = \(String(describing: nativeURL))",
      "url = \(url)",
      "returnURL = \(returnURL)",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  internal init(
    nativeURL: URL?,
    url: URL,
    returnURL: URL,
    allResponseFields: [AnyHashable: Any]
  ) {
    self.nativeURL = nativeURL
    self.url = url
    self.returnURL = returnURL
    self.allResponseFields = allResponseFields
    super.init()
  }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentActionAlipayHandleRedirect: STPAPIResponseDecodable {

  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let dict = response,
      let urlString = dict["url"] as? String,
      let url = URL(string: urlString),
      let returnURLString = dict["return_url"] as? String,
      let returnURL = URL(string: returnURLString)
    else {
      return nil
    }

    let nativeURL: URL?
    if let nativeURLString = dict["native_url"] as? String {
      nativeURL = URL(string: nativeURLString)
    } else {
      nativeURL = nil
    }

    return STPIntentActionAlipayHandleRedirect(
      nativeURL: nativeURL,
      url: url,
      returnURL: returnURL,
      allResponseFields: dict) as? Self
  }

}
