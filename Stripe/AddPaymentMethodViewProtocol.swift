//
//  AddPaymentMethodViewProtocol.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/18/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

protocol AddPaymentMethodViewDelegate: AnyObject {
    func didUpdate(_ addPaymentMethodView: AddPaymentMethodView)
}

protocol AddPaymentMethodView: UIView {
    var delegate: AddPaymentMethodViewDelegate? { get set }
    /// The type of payment method this view is displaying
    var paymentMethodType: STPPaymentMethodType { get }
    /// Return nil if incomplete or invalid
    var paymentMethodParams: STPPaymentMethodParams? { get }
    var shouldSavePaymentMethod: Bool { get }
    /// Returns true iff we could map the error to one of the displayed fields
    func setErrorIfNecessary(for apiError: Error) -> Bool
}
