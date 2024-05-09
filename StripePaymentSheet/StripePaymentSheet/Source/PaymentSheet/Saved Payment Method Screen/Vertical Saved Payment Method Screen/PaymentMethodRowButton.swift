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

protocol PaymentMethodRowButtonDelegate: AnyObject {
    func didSelectButton(_ button: PaymentMethodRowButton)
    // TODO(porter) Add did delete and did update
}

// TODO: Make this use RowButton internally
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

    weak var delegate: PaymentMethodRowButtonDelegate?

    // MARK: Private properties
    private let viewModel: ViewModel

    // MARK: Private views

    private lazy var paymentMethodImageView: UIImageView = {
        let imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        // TODO(porter) Do we want to round the corners?
        return imageView
    }()

    private lazy var label: UILabel = {
        return .makeVerticalRowButtonLabel(text: viewModel.text, appearance: viewModel.appearance)
    }()

    private lazy var circleView: CheckmarkCircleView = {
        let circleView = CheckmarkCircleView(fillColor: viewModel.appearance.colors.primary)
        circleView.alpha = 0.0
        return circleView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView.makeRowButtonContentStackView(arrangedSubviews: [paymentMethodImageView, label, .makeSpacerView(), circleView])
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

        addAndPinSubview(shadowRoundedRect)
        NSLayoutConstraint.activate([
            paymentMethodImageView.heightAnchor.constraint(equalToConstant: 20), // Hardcoded from figma
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
