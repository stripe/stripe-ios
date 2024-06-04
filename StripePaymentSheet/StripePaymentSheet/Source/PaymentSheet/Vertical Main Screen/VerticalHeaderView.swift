//
//  VerticalHeaderView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/4/24.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class VerticalHeaderView: UIView {
    
    private lazy var label: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: .default)
        return label
    }()
    
    private var imageView: PaymentMethodTypeImageView?
    
    private lazy var stackView: UIStackView = {
       let stackView = UIStackView(arrangedSubviews: [label])
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    init() {
        super.init(frame: .zero)
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
        let imageView = PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, backgroundColor: .white)
        stackView.insertArrangedSubview(imageView, at: 0)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        self.imageView = imageView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
