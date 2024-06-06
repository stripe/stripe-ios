//
//  VerticalHeaderView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/4/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class VerticalHeaderView: UIView {

    private lazy var label: UILabel = {
        return PaymentSheetUI.makeHeaderLabel(appearance: appearance)
    }()

    private var imageView: PaymentMethodTypeImageView?

    private lazy var stackView: UIStackView = {
       let stackView = UIStackView(arrangedSubviews: [label])
        stackView.spacing = 12
        return stackView
    }()

    private let appearance: PaymentSheet.Appearance

    init(text: String, appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        label.text = text
        addAndPinSubview(stackView)
    }

    func set(text: String) {
        label.text = text
        imageView?.removeFromSuperview()
        imageView = nil
    }

    func update(with paymentMethodType: PaymentSheet.PaymentMethodType) {
        label.text = paymentMethodType.displayName

        imageView?.removeFromSuperview()
        let imageView = PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, backgroundColor: appearance.colors.background)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.insertArrangedSubview(imageView, at: 0)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20),
        ])

        self.imageView = imageView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
