//
//  PaymentMethodRowButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/9/24.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@_spi(STP) import StripePaymentsUI

protocol PaymentMethodRowDelegate: AnyObject {
    func didSelectRow(_ row: PaymentMethodRowButton)
    // TODO(porter) Add did delete and did update
}

// TODO(porter) Does this need to be a button?
final class PaymentMethodRowButton: UIView {
    
    struct ViewModel {
        let appearance: PaymentSheet.Appearance
        let text: String
        let image: UIImage
        // TODO(porter) Add can remove and can update
    }
    
    // TODO(porter) Maybe expand this into an enum of (selected, unselected, editing)
    public var isSelected: Bool {
        get {
            return shadowRoundedRect.isSelected
        }
        
        set {
            shadowRoundedRect.isSelected = newValue
            circleView.alpha = newValue ? 1.0 : 0.0
        }
    }

    private let viewModel: ViewModel
    private let height = 44.0 // Hardcoded height from figma
    
    weak var delegate: PaymentMethodRowDelegate?
    
    private lazy var paymentMethodImageView: UIImageView = {
        let imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = viewModel.text
        label.font = viewModel.appearance.scaledFont(for: viewModel.appearance.font.base.medium, style: .callout, maximumPointSize: 20)
        return label
    }()
    
    private lazy var circleView: CheckmarkCircleView = {
        let circleView = CheckmarkCircleView(fillColor: viewModel.appearance.colors.primary)
        circleView.alpha = 0.0
        return circleView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [paymentMethodImageView, label, UIView.spacerView, circleView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.setCustomSpacing(12, after: paymentMethodImageView)
        return stackView
    }()
    
    private lazy var shadowRoundedRect: ShadowedRoundedRectangle = {
        let shadowRoundedRect = ShadowedRoundedRectangle(appearance: viewModel.appearance)
        shadowRoundedRect.translatesAutoresizingMaskIntoConstraints = false
        shadowRoundedRect.addAndPinSubview(stackView)
        return shadowRoundedRect
    }()

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        
        addSubview(shadowRoundedRect)
        circleView.alpha = 0.0
        NSLayoutConstraint.activate([
            shadowRoundedRect.topAnchor.constraint(equalTo: topAnchor),
            shadowRoundedRect.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadowRoundedRect.trailingAnchor.constraint(equalTo: trailingAnchor),
            shadowRoundedRect.bottomAnchor.constraint(equalTo: bottomAnchor),
            shadowRoundedRect.heightAnchor.constraint(equalToConstant: height)
        ])
        // TODO(accessibility)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleTap() {
        shadowRoundedRect.isSelected = true
        circleView.alpha = 1.0
        delegate?.didSelectRow(self)
    }
    
}

// MARK: Extensions
extension UIView {
    public static var spacerView: UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        view.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return view
    }
}
