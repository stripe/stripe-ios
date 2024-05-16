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
    func didSelectButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
    func didSelectRemoveButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
    func didSelectEditButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
}

// TODO: Make this use RowButton internally
final class PaymentMethodRowButton: UIView {

    struct ViewModel {
        let appearance: PaymentSheet.Appearance
        let paymentMethod: STPPaymentMethod
        // TODO(porter) Add can remove and can update
    }

    enum State {
        case selected
        case unselected
        case editing
    }

    // MARK: Internal properties
    var state: State = .unselected {
        didSet {
            previousState = oldValue

            selectionTapGesture.isEnabled = !isEditing
            shadowRoundedRect.isSelected = isSelected
            circleView.isHidden = !isSelected
            editButton.isHidden = !isEditing // TODO(porter) only show if we can edit
            removeButton.isHidden = !isEditing // TOOD(porter) only show if we can remove
        }
    }

    private(set) var previousState: State = .unselected

    var isSelected: Bool {
        switch state {
        case .selected:
            return true
        case .unselected, .editing:
            return false
        }
    }

    var isEditing: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing:
            return true
        }
    }

    weak var delegate: PaymentMethodRowButtonDelegate?

    // MARK: Private properties
    private let paymentMethod: STPPaymentMethod
    private let appearance: PaymentSheet.Appearance

    // MARK: Private views

    private lazy var paymentMethodImageView: UIImageView = {
        let imageView = UIImageView(image: paymentMethod.makeSavedPaymentMethodRowImage())
        imageView.contentMode = .scaleAspectFit
        // TODO(porter) Do we want to round the corners?
        return imageView
    }()

    private lazy var label: UILabel = {
        return .makeVerticalRowButtonLabel(text: paymentMethod.paymentSheetLabel, appearance: appearance)
    }()

    // TODO(porter) Refactor CircleIconView out of SavedPaymentMethodCollectionView once it is deleted
    private lazy var circleView: SavedPaymentMethodCollectionView.CircleIconView = {
        let circleView = SavedPaymentMethodCollectionView.CircleIconView(icon: .icon_checkmark,
                                                                         fillColor: appearance.colors.primary)
        circleView.isHidden = true
        return circleView
    }()

    lazy var removeButton: CircularButton = {
        let removeButton = CircularButton(style: .remove, iconColor: .white)
        removeButton.backgroundColor = appearance.colors.danger
        removeButton.isHidden = true
        removeButton.addTarget(self, action: #selector(handleRemoveButtonTapped), for: .touchUpInside)
        return removeButton
    }()

    private lazy var editButton: CircularButton = {
        let editButton = CircularButton(style: .edit, iconColor: .white)
        editButton.backgroundColor = appearance.colors.icon
        editButton.isHidden = true
        editButton.addTarget(self, action: #selector(handleEditButtonTapped), for: .touchUpInside)
        return editButton
    }()

    private lazy var stackView: UIStackView = {
        return UIStackView.makeRowButtonContentStackView(arrangedSubviews: [paymentMethodImageView, label, .makeSpacerView(), circleView, editButton, removeButton])
    }()

    private lazy var shadowRoundedRect: ShadowedRoundedRectangle = {
        let shadowRoundedRect = ShadowedRoundedRectangle(appearance: appearance)
        shadowRoundedRect.translatesAutoresizingMaskIntoConstraints = false
        shadowRoundedRect.addAndPinSubview(stackView)
        return shadowRoundedRect
    }()

    private lazy var selectionTapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(handleSelectionTap))
    }()

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance) {
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        super.init(frame: .zero)

        addAndPinSubview(shadowRoundedRect)
        NSLayoutConstraint.activate([
            paymentMethodImageView.heightAnchor.constraint(equalToConstant: 20), // Hardcoded from figma
            paymentMethodImageView.widthAnchor.constraint(equalToConstant: 25),
        ])
        // TODO(porter) accessibility?
        addGestureRecognizer(selectionTapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handlers
    @objc private func handleSelectionTap() {
        state = .selected
        delegate?.didSelectButton(self, with: paymentMethod)
    }

    @objc private func handleEditButtonTapped() {
        delegate?.didSelectEditButton(self, with: paymentMethod)
    }

    @objc private func handleRemoveButtonTapped() {
        delegate?.didSelectRemoveButton(self, with: paymentMethod)
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
