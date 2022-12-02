//
//  STPBlocks.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

/// A callback to be run with a response from the Stripe API containing information about the online status of FPX banks.
/// - Parameters:
///   - bankStatusResponse:    The response from Stripe containing the status of the various banks. Will be nil if an error occurs. - seealso: STPFPXBankStatusResponse
///   - error:                   The error returned from the response, or nil if none occurs.
typealias STPFPXBankStatusCompletionBlock = (STPFPXBankStatusResponse?, Error?) -> Void

/// These values control the labels used in the shipping info collection form.
@objc public enum STPShippingType: Int {
    /// Shipping the purchase to the provided address using a third-party
    /// shipping company.
    case shipping
    /// Delivering the purchase by the seller.
    case delivery
}

/// An enum representing the status of a shipping address validation.
@objc public enum STPShippingStatus: Int {
    /// The shipping address is valid.
    case valid
    /// The shipping address is invalid.
    case invalid
}

/// A callback to be run with a validation result and shipping methods for a
/// shipping address.
/// - Parameters:
///   - status: An enum representing whether the shipping address is valid.
///   - shippingValidationError: If the shipping address is invalid, an error describing the issue with the address. If no error is given and the address is invalid, the default error message will be used.
///   - shippingMethods: The shipping methods available for the address.
///   - selectedShippingMethod: The default selected shipping method for the address.
public typealias STPShippingMethodsCompletionBlock = (
    STPShippingStatus, Error?, [PKShippingMethod]?, PKShippingMethod?
) -> Void
