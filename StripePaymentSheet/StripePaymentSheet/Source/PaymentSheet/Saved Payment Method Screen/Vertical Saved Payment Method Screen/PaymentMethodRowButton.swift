//
//  PaymentMethodRowButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/9/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol PaymentMethodRowDelegate: AnyObject {
    func didSelectButton(_ button: PaymentMethodRowButton)
    // TODO(porter) Add did delete and did update
}

final class PaymentMethodRowButton: UIView {

    struct ViewModel {
        let appearance: PaymentSheet.Appearance
        let text: String
        let image: UIImage
        // TODO(porter) Add can remove and can update
    }

    // MARK: Internal properties
    // TODO(porter) Maybe expand this into an enum of (selected, unselected, editing) state
    var isSelected: Bool {
        get {
            return shadowRoundedRect.isSelected
        }

        set {
            shadowRoundedRect.isSelected = newValue
            circleView.alpha = newValue ? 1.0 : 0.0
        }
    }

    weak var delegate: PaymentMethodRowDelegate?

    // MARK: Private properties
    private let viewModel: ViewModel
    private let height = 44.0 // Hardcoded height from figma

    // MARK: Private views

    private lazy var paymentMethodImageView: UIImageView = {
        let imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        // TODO(porter) Do we want to round the corners?
        return imageView
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = viewModel.text
        label.font = viewModel.appearance.scaledFont(for: viewModel.appearance.font.base.medium,
                                                     style: .callout,
                                                     maximumPointSize: 25)
        label.adjustsFontForContentSizeCategory = true
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
        stackView.setCustomSpacing(12, after: paymentMethodImageView) // Hardcoded from figma
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
        NSLayoutConstraint.activate([
            shadowRoundedRect.topAnchor.constraint(equalTo: topAnchor),
            shadowRoundedRect.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadowRoundedRect.trailingAnchor.constraint(equalTo: trailingAnchor),
            shadowRoundedRect.bottomAnchor.constraint(equalTo: bottomAnchor),
            shadowRoundedRect.heightAnchor.constraint(equalToConstant: height),
            paymentMethodImageView.heightAnchor.constraint(equalToConstant: 20),
            paymentMethodImageView.widthAnchor.constraint(equalToConstant: 25),
        ])
        // TODO(porter) accessibility?
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handlers
    @objc private func handleTap() {
        shadowRoundedRect.isSelected = true
        circleView.alpha = 1.0
        delegate?.didSelectButton(self)
    }

}

// MARK: Helper extensions
extension UIView {
    static var spacerView: UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        view.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return view
    }
}
