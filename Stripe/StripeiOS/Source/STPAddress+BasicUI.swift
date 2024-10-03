//
//  STPAddress+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

/// What set of billing address information you need to collect from your user.
///
/// @note If the user is from a country that does not use zip/postal codes,
/// the user may not be asked for one regardless of this setting.
@objc
public enum STPBillingAddressFields: UInt {
    /// No billing address information
    case none
    /// Just request the user's billing postal code
    case postalCode
    /// Request the user's full billing address
    case full
    /// Just request the user's billing name
    case name
    /// Just request the user's billing ZIP (synonym for STPBillingAddressFieldsZip)
    @available(*, deprecated, message: "Use STPBillingAddressFields.postalCode instead")
    case zip
}
