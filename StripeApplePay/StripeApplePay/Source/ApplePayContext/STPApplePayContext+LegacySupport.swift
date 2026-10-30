//
//  STPApplePayContext+LegacySupport.swift
//  StripeApplePay
//
//  Created by David Estes on 1/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

/// Internal Apple Pay class. Do not use.
/// :nodoc:
@_spi(InternalOnlyAPI) public class _stpinternal_ApplePayContextDidCreatePaymentMethodStorage: NSObject {
    @_spi(InternalOnlyAPI) public weak var delegate: _stpinternal_STPApplePayContextDelegateBase?
    @_spi(InternalOnlyAPI) public var context: STPApplePayContext
    @_spi(InternalOnlyAPI) public var paymentMethod: StripeAPI.PaymentMethod
    @_spi(InternalOnlyAPI) public var paymentInformation: PKPayment
    @_spi(InternalOnlyAPI) public var completion: STPIntentClientSecretCompletionBlock

    @_spi(InternalOnlyAPI) public init(
        delegate: _stpinternal_STPApplePayContextDelegateBase,
        context: STPApplePayContext,
        paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    ) {
        self.delegate = delegate
        self.context = context
        self.paymentMethod = paymentMethod
        self.paymentInformation = paymentInformation
        self.completion = completion
    }
}

/// Internal Apple Pay class. Do not use.
/// :nodoc:
@_spi(InternalOnlyAPI) public class _stpinternal_ApplePayContextDidCompleteStorage: NSObject {
    @_spi(InternalOnlyAPI) public weak var delegate: _stpinternal_STPApplePayContextDelegateBase?
    @_spi(InternalOnlyAPI) public var context: STPApplePayContext
    @_spi(InternalOnlyAPI) public var status: STPApplePayContext.PaymentStatus
    @_spi(InternalOnlyAPI) public var error: Error?

    @_spi(InternalOnlyAPI) public init(
        delegate: _stpinternal_STPApplePayContextDelegateBase,
        context: STPApplePayContext,
        status: STPApplePayContext.PaymentStatus,
        error: Error?
    ) {
        self.delegate = delegate
        self.context = context
        self.status = status
        self.error = error
    }
}
