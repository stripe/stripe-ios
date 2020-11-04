//
//  STPSourceProtocol.swift
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Objects conforming to this protocol can be attached to a Stripe Customer object
/// as a payment source.
/// - seealso: https://stripe.com/docs/api#customer_object-sources
@objc public protocol STPSourceProtocol: NSObjectProtocol {
  /// The Stripe ID of the source.
  var stripeID: String { get }
}
