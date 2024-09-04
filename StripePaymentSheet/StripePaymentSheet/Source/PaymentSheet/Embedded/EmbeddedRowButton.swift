//
//  EmbeddedRowButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/24.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

class EmbeddedRowButton: UIView {
    let rowButton: RowButton
    let appearance: PaymentSheet.Appearance
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        return stackView
    }()
    
    private lazy var radioButton: RadioButton? = {
        guard appearance.paymentOptionView.style == .flatRadio else { return nil }
        return RadioButton(appearance: appearance) {
            self.rowButton.didTap(self.rowButton)
        }
    }()
    
    private lazy var checkmarkView: CheckmarkView? = {
        guard appearance.paymentOptionView.style == .flatCheck else { return nil }
        return CheckmarkView()
    }()
    
    var isSelected: Bool = false {
        didSet {
            // TODO(porter) Handle better other cases
            radioButton?.isOn = isSelected
            rowButton.isSelected = isSelected
        }
    }
    
    init(appearance: PaymentSheet.Appearance, rowButton: RowButton) {
        self.appearance = appearance
        self.rowButton = rowButton
        super.init(frame: .zero)
        self.backgroundColor = appearance.colors.componentBackground
        for view in [radioButton, rowButton].compactMap({ $0 }) {
            view.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(view)
        }
        
        // TODO(porter) Pass in left/right insets for content padding
        addAndPinSubview(stackView,
                         insets: .init(top: appearance.paymentOptionView.paymentMethodRow.additionalInsets?.top ?? 4,
                                       leading: 0,
                                       bottom: appearance.paymentOptionView.paymentMethodRow.additionalInsets?.bottom ?? 4,
                                       trailing: 0))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
