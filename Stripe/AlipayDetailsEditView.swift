//
//  AlipayDetailsEditView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 1/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// A view to collect PaymentMethod details for Alipay.
/// There are no required fields.
class AlipayDetailsEditView: UIView {
    weak var delegate: AddPaymentMethodViewDelegate?
    let billingAddressCollectionLevel: PaymentSheet.BillingAddressCollectionLevel
    private lazy var billingAddressEditView: BillingAddressEditView? = {
        switch billingAddressCollectionLevel {
        case .required:
            let details = BillingAddressEditView()
            details.delegate = self
            return details
        case .automatic:
            return nil
        }
    }()

    init(billingAddressCollectionLevel: PaymentSheet.BillingAddressCollectionLevel) {
        self.billingAddressCollectionLevel = billingAddressCollectionLevel
        super.init(frame: .zero)
        directionalLayoutMargins = .zero
        let stackView = UIStackView(arrangedSubviews: [billingAddressEditView].compactMap { $0 })
        stackView.axis = .vertical
        stackView.spacing = 16
        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - AddPaymentMethodView
extension AlipayDetailsEditView: AddPaymentMethodView {
    var paymentMethodParams: STPPaymentMethodParams? {
        // Only return non-nil if valid and complete
        if billingAddressCollectionLevel == .required
            && billingAddressEditView?.billingDetails == nil
        {
            return nil
        }
        return STPPaymentMethodParams(
            alipay: STPPaymentMethodAlipayParams(),
            billingDetails: billingAddressEditView?.billingDetails, metadata: nil)
    }
    var paymentMethodType: STPPaymentMethodType {
        return .alipay
    }
    var shouldSavePaymentMethod: Bool {
        return false
    }
    func setErrorIfNecessary(for apiError: Error) -> Bool {
        return false  // there are no errors we can display here
    }
}

// MARK: - BillingAddressEditViewDelegate
extension AlipayDetailsEditView: BillingAddressEditViewDelegate {
    func didUpdate(_ billingAddressEditView: BillingAddressEditView) {
        delegate?.didUpdate(self)
    }
}
