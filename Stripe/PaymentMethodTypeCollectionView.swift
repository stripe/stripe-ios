//
//  PaymentMethodTypeCollectionView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol PaymentMethodTypeCollectionViewDelegate: AnyObject {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView)
}

// This is a placeholder view; it is currently unused
class PaymentMethodTypeCollectionView: UIView {
    var selected: STPPaymentMethodType = .card

    init(paymentMethodTypes: [STPPaymentMethodType], delegate: PaymentMethodTypeCollectionViewDelegate) {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
